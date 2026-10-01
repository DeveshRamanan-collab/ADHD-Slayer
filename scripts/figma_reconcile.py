#!/usr/bin/env python3
"""figma_reconcile.py <fileKey> [--candidates <page-slug>] [--strict] [--root DIR]

Reconciles the Figma structural index with the analysis rows (Phase 3/4, G1).

Figma side, from every docs/figma/raw/<fileKey>/<page-slug>/nodes.json:
  top-level frames  FRAME/COMPONENT/COMPONENT_SET/INSTANCE whose parent is the page (CANVAS)
                    or a SECTION on the page (a chain of SECTIONs up to the page)
  sections          SECTION nodes on the page (each gets a Kind=section FRM- row, so the
                    section-1 inventory can equal the depth-1 count; see validate_analysis.py)
  component sets    every COMPONENT_SET
  components        every COMPONENT; one whose parent is a COMPONENT_SET is a variant covered
                    by its set's row and needs no row of its own
  interactive-element candidates  any node that (a) carries a prototype reaction ("reactions"
                    in the index), (b) is an INSTANCE whose mainComponentName matches the Phase 3
                    regex, or (c) has a name matching it:
                    (?i)button|toggle|switch|chip|tab|segment|picker|field|input|slider|stepper|link|control|row|card|sheet|menu|fab|cta
Row side, from docs/FIGMA_AUDIT.md (or docs/figma/analysis/*.md when the audit is not yet
assembled): node ids in SCR-/FRM-/CMP- rows (### headings and table rows whose first cell is
the id), INT- rows (#### headings and table rows) and NON-INTERACTIVE lines (the node id must
be on the same line). Fenced code blocks are skipped.

Prints per page: candidates found vs rows present, ids missing on each side, Platform-column
violations (Watch page rows must be `Watch`; Glanceables rows one of Home-widget, Lock-widget,
Live-Activity, Control-Center).
--candidates <slug>  prints the candidate list for one page in 04-T11 block order (one ###
    block per top-level frame/section/component set in document order, each followed by the
    #### candidates inside it) and exits.
--strict  exit 1 on any missing id or violation (without it, problems are printed, exit 0).
Exit 2 with a message if a page folder has raw text but no nodes.json, or nodes.json is malformed.

Rules: MISSING-ROW (Figma node without a row), MISSING-NODE (row whose node id is not in the
page's nodes.json), MISSING-INT (candidate without INT-/NON-INTERACTIVE), DUP-ROW (one node under
two different SCR/FRM/CMP ids), PLATFORM, NOPAGE (analysis file without a nodes.json page),
NONODES (page folder with raw text but no nodes.json).
"""
import sys, re, os, json, argparse, pathlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import figma_fingerprint as ff  # noqa: E402

CAND_RE = re.compile(r"(?i)button|toggle|switch|chip|tab|segment|picker|field|input|slider|stepper|link|control|row|card|sheet|menu|fab|cta")
FRAME_TYPES = {"FRAME", "COMPONENT", "COMPONENT_SET", "INSTANCE"}
GLANCE = {"Home-widget", "Lock-widget", "Live-Activity", "Control-Center"}
ROW_PREFIX = re.compile(r"(SCR|FRM|CMP|INT)-\d{4}")
FENCE = "`" * 3


# ---------------------------------------------------------------- Figma side
class Page:
    def __init__(self, pg):
        self.slug, self.path, d = pg["slug"], pg["path"], pg["data"]
        self.name, self.id = d["page"], d["pageId"]
        self.nodes = d["nodes"]
        self.text = pg["text"]
        self.by_id = {n["id"]: n for n in self.nodes}
        self.children = {}
        for n in self.nodes:
            self.children.setdefault(n["parentId"], []).append(n["id"])

    def line_of(self, nid):
        i = self.text.find(f'"id": "{nid}"')
        return self.text.count("\n", 0, i) + 1 if i >= 0 else 1

    def parent_type(self, n):
        p = self.by_id.get(n["parentId"])
        return "CANVAS" if p is None else p["type"]

    def on_page_via_sections(self, n):
        """True if the parent chain up to the page consists only of SECTIONs."""
        pid = n["parentId"]
        while pid != self.id:
            p = self.by_id.get(pid)
            if p is None or p["type"] != "SECTION":
                return False
            pid = p["parentId"]
        return True

    def top_level_frames(self):
        return [n for n in self.nodes if n["type"] in FRAME_TYPES and self.on_page_via_sections(n)]

    def sections(self):
        return [n for n in self.nodes if n["type"] == "SECTION" and self.on_page_via_sections(n)]

    def structural(self):
        """Nodes that need exactly one SCR-/FRM-/CMP- row, in document order."""
        want = {n["id"] for n in self.top_level_frames()} | {n["id"] for n in self.sections()}
        for n in self.nodes:
            if n["type"] == "COMPONENT_SET" or (n["type"] == "COMPONENT" and self.parent_type(n) != "COMPONENT_SET"):
                want.add(n["id"])
        return [n for n in self.nodes if n["id"] in want]

    def count(self, t):
        return sum(1 for n in self.nodes if n["type"] == t)

    def variants(self):
        return sum(1 for n in self.nodes if n["type"] == "COMPONENT" and self.parent_type(n) == "COMPONENT_SET")

    def descendants(self, nid):
        out, todo = 0, list(self.children.get(nid, []))
        while todo:
            c = todo.pop()
            out += 1
            todo += self.children.get(c, [])
        return out

    def candidates(self):
        """[(node, [reasons])] in document order."""
        out = []
        for n in self.nodes:
            why = []
            if n.get("reactions"):
                why.append("reaction")
            mcn = n.get("mainComponentName")
            if n["type"] == "INSTANCE" and mcn and CAND_RE.search(mcn):
                why.append(f"instance-of:{mcn}")
            if CAND_RE.search(n.get("name", "")):
                why.append("name")
            if why:
                out.append((n, why))
        return out

    def block_owner(self, nid, blocks):
        """Nearest ancestor (or self) that is a non-SECTION block; else nearest SECTION block; else None."""
        cur, section = nid, None
        while cur and cur != self.id:
            if cur in blocks:
                if self.by_id[cur]["type"] != "SECTION":
                    return cur
                section = section or cur
            cur = self.by_id.get(cur, {}).get("parentId")
        return section

    def is_watch(self):
        return bool(re.search(r"(?i)\bwatch\b", self.name + " " + self.slug))

    def is_glanceables(self):
        return bool(re.search(r"(?i)glanceable", self.name + " " + self.slug))


def load(root, key):
    """Return (pages, exit_code). Exit 2 on a page folder with raw text but no nodes.json."""
    base = ff.raw_dir(root, key)
    code = 0
    if base.is_dir():
        for d in sorted(base.iterdir()):
            if d.is_dir() and not ff.TOOL_DIR.match(d.name) and not (d / "nodes.json").exists():
                raw = [f for f in d.iterdir() if f.is_file()]
                if raw:
                    ff.err(d / "nodes.json", 0, "NONODES",
                           f"page folder '{d.name}' has raw text ({', '.join(f.name for f in raw)}) but no nodes.json; "
                           f"build it with figma_fingerprint.py --build {d.name}=<pageNodeId>")
                    code = 2
    pages, fails = ff.load_pages(root, key)
    if fails:
        code = 2
    if not pages and not fails and code == 0:
        ff.err(base, 0, "NONODES", "no <page-slug>/nodes.json found")
        code = 2
    return [Page(p) for p in pages], code


# ---------------------------------------------------------------- row side
def strip_cell(c):
    return c.strip().strip("`").strip("*").strip()


def node_id_in(cell):
    c = strip_cell(cell)
    if ff.NODE_ID.fullmatch(c):
        return c
    m = ff.NODE_ID.search(c)
    return m.group(0) if m else None


def parse_rows(path):
    """Rows of one Markdown file: list of dicts {id, prefix, node, platform, line, kind}."""
    rows = []
    lines = path.read_text(encoding="utf-8", errors="replace").split("\n")
    fence = False
    header = None
    for i, raw in enumerate(lines, 1):
        if raw.startswith(FENCE):
            fence = not fence
            continue
        if fence:
            continue
        line = raw.rstrip()
        h = re.match(r"^(#{3,4})\s+\**((SCR|FRM|CMP|INT)-\d{4})\**\s*\|(.*)$", line)
        if h:
            fields = [h.group(2)] + h.group(4).split("|")
            node = node_id_in(fields[2]) if len(fields) > 2 else None
            platform = strip_cell(fields[5]) if h.group(1) == "###" and len(fields) > 5 else None
            rows.append({"id": h.group(2), "prefix": h.group(3), "node": node, "platform": platform,
                         "line": i, "kind": "heading"})
            header = None
            continue
        if line.startswith("|"):
            cells = [c for c in line.strip().strip("|").split("|")]
            if re.match(r"^\|[\s:|-]+\|?$", line.strip()):
                continue
            first = strip_cell(cells[0])
            m = ROW_PREFIX.fullmatch(first)
            if not m:
                if any(re.search(r"(?i)node id", c) for c in cells):
                    header = [strip_cell(c).lower() for c in cells]
                continue
            node_col = next((j for j, c in enumerate(header or []) if "node id" in c), 2)
            plat_col = next((j for j, c in enumerate(header or []) if c.startswith("platform")), None)
            if plat_col is None and header is None:
                plat_col = 4
            rows.append({"id": first, "prefix": m.group(1),
                         "node": node_id_in(cells[node_col]) if node_col < len(cells) else None,
                         "platform": strip_cell(cells[plat_col]) if plat_col is not None and plat_col < len(cells) else None,
                         "line": i, "kind": "table"})
            continue
        header = None if not line.strip() else header
        if "NON-INTERACTIVE" in line and not re.search(r"NON-INTERACTIVE rows", line):
            for nid in ff.NODE_ID.findall(line):
                rows.append({"id": "NON-INTERACTIVE", "prefix": "NI", "node": nid, "platform": None,
                             "line": i, "kind": "non-interactive"})
    return rows


def row_sources(root):
    audit = pathlib.Path(root) / "docs/FIGMA_AUDIT.md"
    if audit.exists():
        return [(audit, None)]
    adir = pathlib.Path(root) / "docs/figma/analysis"
    if not adir.is_dir():
        return []
    return [(p, p.stem) for p in sorted(adir.glob("*.md"))]


def assign_rows(root, pages):
    """Return ({slug: [rows]}, problems)."""
    by_slug = {p.slug: [] for p in pages}
    node_page = {}
    for p in pages:
        for n in p.nodes:
            node_page.setdefault(n["id"], p.slug)
        node_page.setdefault(p.id, p.slug)
    probs = []
    for path, slug in row_sources(root):
        rows = parse_rows(path)
        for r in rows:
            r["file"] = path
        if slug is not None:
            if slug not in by_slug:
                probs.append((path, 1, "NOPAGE", f"analysis file for page slug '{slug}' but no nodes.json page with that slug"))
                continue
            by_slug[slug] += rows
        else:
            for r in rows:
                s = node_page.get(r["node"])
                if s is None:
                    probs.append((path, r["line"], "MISSING-NODE", f"{r['id']} node {r['node'] or '(none)'} is in no nodes.json"))
                else:
                    by_slug[s].append(r)
    return by_slug, probs


# ---------------------------------------------------------------- reconciliation
def reconcile_page(p, rows):
    """Return (summary dict, problems list)."""
    probs = []
    struct = p.structural()
    struct_ids = {n["id"] for n in struct}
    srows = [r for r in rows if r["prefix"] in ("SCR", "FRM", "CMP")]
    irows = [r for r in rows if r["prefix"] == "INT"]
    nrows = [r for r in rows if r["prefix"] == "NI"]
    row_nodes = {}
    for r in srows:
        if r["node"] is None:
            probs.append((r["file"], r["line"], "MISSING-NODE", f"{r['id']} row has no node id"))
            continue
        row_nodes.setdefault(r["node"], set()).add(r["id"])
        if r["node"] not in p.by_id:
            probs.append((r["file"], r["line"], "MISSING-NODE", f"{r['id']} node {r['node']} is not in {ff.rel(p.path)}"))
        elif r["node"] not in struct_ids:
            probs.append((r["file"], r["line"], "MISSING-NODE",
                          f"{r['id']} node {r['node']} ({p.by_id[r['node']]['type']}) is not a top-level frame, section, "
                          f"component or component set"))
    for nid, ids in row_nodes.items():
        if len(ids) > 1:
            first = next(r for r in srows if r["node"] == nid)
            probs.append((first["file"], first["line"], "DUP-ROW", f"node {nid} has rows under {', '.join(sorted(ids))}"))
    for n in struct:
        if n["id"] not in row_nodes:
            probs.append((p.path, p.line_of(n["id"]), "MISSING-ROW", f'node {n["id"]} "{n["name"]}" ({n["type"]}) has no SCR-/FRM-/CMP- row'))
    for r in irows + nrows:
        if r["node"] is None:
            probs.append((r["file"], r["line"], "MISSING-NODE", f"{r['id']} row has no node id"))
        elif r["node"] not in p.by_id and r["node"] != p.id and not r["node"].startswith("I"):
            probs.append((r["file"], r["line"], "MISSING-NODE", f"{r['id']} node {r['node']} is not in {ff.rel(p.path)}"))
    covered = {r["node"] for r in irows + nrows}
    cands = p.candidates()
    for n, why in cands:
        if n["id"] not in covered:
            probs.append((p.path, p.line_of(n["id"]), "MISSING-INT",
                          f'candidate {n["id"]} "{n["name"]}" ({n["type"]}; {", ".join(why)}) has no INT- row or NON-INTERACTIVE line'))
    for r in srows + irows:
        plat = r.get("platform")
        if plat is None:
            continue
        if p.is_watch() and plat != "Watch":
            probs.append((r["file"], r["line"], "PLATFORM", f"{r['id']} on the Watch page has Platform '{plat}' (must be Watch)"))
        if p.is_glanceables() and plat not in GLANCE:
            probs.append((r["file"], r["line"], "PLATFORM",
                          f"{r['id']} on Glanceables has Platform '{plat}' (must be one of {', '.join(sorted(GLANCE))})"))
    summary = {"structural": len(struct), "struct_rows": len(row_nodes), "candidates": len(cands),
               "int_rows": len({r['id'] for r in irows}), "ni_lines": len(nrows),
               "components": p.count("COMPONENT"), "component_sets": p.count("COMPONENT_SET"),
               "platform": sum(1 for x in probs if x[2] == "PLATFORM")}
    return summary, probs


def candidate_blocks(p):
    """04-T11 order: [(block node, [(candidate node, reasons)])] plus a page-level block (None)."""
    blocks = p.structural()
    block_ids = {n["id"] for n in blocks}
    grouped = {n["id"]: [] for n in blocks}
    loose = []
    for n, why in p.candidates():
        owner = p.block_owner(n["id"], block_ids)
        (grouped[owner] if owner else loose).append((n, why))
    out = [(b, grouped[b["id"]]) for b in blocks]
    if loose:
        out.append((None, loose))
    return out


def print_candidates(p):
    print(f'# Interaction candidates — page "{p.name}" ({p.slug}, node {p.id}) — 04-T11 block order')
    total = 0
    for b, cands in candidate_blocks(p):
        if b is None:
            print("### page-level (no top-level frame ancestor)")
        else:
            w, h = b.get("width"), b.get("height")
            print(f'### {b["type"]} | {b["name"]} | {b["id"]} | {w}×{h} | descendants {p.descendants(b["id"])}')
        for n, why in cands:
            total += 1
            print(f'#### candidate | {n["name"]} | {n["id"]} | {n["type"]} | {", ".join(why)}')
    print(f"candidates: {total}")


def main():
    ap = argparse.ArgumentParser(description="Reconcile nodes.json with SCR/FRM/CMP/INT rows.",
                                 formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    ap.add_argument("fileKey")
    ap.add_argument("--candidates", metavar="PAGE_SLUG", help="print one page's candidates in 04-T11 block order")
    ap.add_argument("--strict", action="store_true", help="exit 1 on any missing id or violation")
    ap.add_argument("--root", default=".", help="project root (default: current directory)")
    a = ap.parse_args()
    root = pathlib.Path(a.root).resolve()
    pages, code = load(root, a.fileKey)
    if code:
        print("figma_reconcile: stopped (exit 2): fix the index problems above first")
        sys.exit(2)
    if a.candidates:
        p = next((x for x in pages if x.slug == a.candidates), None)
        if p is None:
            ff.err(ff.raw_dir(root, a.fileKey) / a.candidates / "nodes.json", 0, "NOPAGE", f"no page slug '{a.candidates}'")
            sys.exit(2)
        print_candidates(p)
        sys.exit(0)
    by_slug, probs = assign_rows(root, pages)
    src = row_sources(root)
    print(f"figma_reconcile: rows from {', '.join(ff.rel(s) for s, _ in src) if src else 'no analysis files yet'}")
    for p in pages:
        s, pp = reconcile_page(p, by_slug[p.slug])
        probs += pp
        print(f'== page "{p.name}" ({p.slug}, node {p.id}) ==')
        print(f"  frames/sections/components needing rows: {s['structural']} · rows present: {s['struct_rows']} · "
              f"missing rows: {sum(1 for x in pp if x[2] == 'MISSING-ROW')} · rows without Figma node: "
              f"{sum(1 for x in pp if x[2] == 'MISSING-NODE')}")
        print(f"  interaction candidates: {s['candidates']} · INT rows: {s['int_rows']} · NON-INTERACTIVE lines: "
              f"{s['ni_lines']} · candidates missing: {sum(1 for x in pp if x[2] == 'MISSING-INT')}")
        print(f"  components: {s['components']} · component sets: {s['component_sets']} · platform violations: {s['platform']}")
    for f in probs:
        ff.err(*f)
    print(f"figma_reconcile: {len(pages)} pages, {len(probs)} problems")
    sys.exit(1 if probs and a.strict else 0)


if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
