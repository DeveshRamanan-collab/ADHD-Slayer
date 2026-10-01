#!/usr/bin/env python3
"""figma_read_plan.py <fileKey> [--figjam <boardKey>:<nodeId>] [--include-variants] [--reserve N] [--root DIR]

Generates docs/figma/read-plan.md (Phase 1.4) from the nodes.json set, docs/figma/TOOL_COVERAGE.md
and docs/figma/read-ledger.md. Re-run after every batch: it is the only place a read is scheduled.

One line per planned read: tier T1-T12, tool, node id, page, frame name, Kind (heuristic from type,
size and name; the analyst assigns the final Kind), variant axis, base-variant flag, planned epoch,
status (planned / done / failed / skipped-variant). Totals per tier, per epoch and per status and
the cap are at the top.

Tiers:
 T1  get_metadata root + one per page
 T2  get_variable_defs on the Foundations and Components pages (when neither page exists: on the
     page(s) holding the most COMPONENT/COMPONENT_SET nodes, at most two)
 T3  get_figjam on the flows board (only with --figjam; the board is not in nodes.json)
 T4  get_libraries once
 T5  get_design_context, base variant of every top-level frame on Prototype-flow pages in MVP order
     Onboarding > Today & Tasks > Medication & Focus window > Recovery & Support > Glanceables >
     Watch > Settings & Privacy, then pages matching no known page name (Cover, Prototype, Handoff
     and unmatched names) in page order
 T6  get_motion_context on the Prototype page and on every top-level frame whose name matches
     (?i)anim|transition|motion|haptic|ring
 T7  get_design_context per component set and per other top-level frame on Components/Foundations
 T8  get_design_context, base variants on Lifestyles (v1) and v1 features
 T9  get_design_context, one frame per variant axis per page (dark, Spark, DynType-XXXL, Discreet,
     375pt, ProMax)
 T10 the remaining mode variants: status skipped-variant (metadata-only-variant) unless
     --include-variants is given (budget remains after T11)
 T11 Future: metadata only, except device-sized frames whose name matches an MVP page name
 T12 get_screenshot, one per SECTION (or page without sections) containing a frame an analysis
     file lists under "layout ambiguous", at most 40 in total
A get_design_context frame with > 400 descendants is expanded to its direct children (recursively);
a frame whose ledger row is `truncated` is marked failed and re-planned as its children.

Status: done when the ledger has an `ok` row for that node and tool; failed when its latest row is
`truncated` or `error`; skipped-variant for T10 lines; planned otherwise. Planned epoch: done lines
carry the epoch of their ledger row; planned/failed lines fill the current epoch's planned capacity
(cap - reserve - reads already in the epoch) and then later epochs of (cap - reserve) each.
TOOL_COVERAGE.md: a table row whose first cell names a tool and whose Available/Status column reads
no/unavailable/absent/blocked/denied removes that tool's lines (listed in the header). Absent file:
every tool is assumed available and the header says so.

Rules: TIME (ledger timestamp without seconds or offset), LEDGER (malformed ledger row),
NODES (index problems; exit 2). Exit 0 ok; 1 ledger problems (the plan is still written); 2 no index.
"""
import sys, re, os, json, argparse, pathlib, datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import figma_fingerprint as ff  # noqa: E402
import figma_reconcile as fr    # noqa: E402

TIME_OK = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-]\d{2}:?\d{2})$")
AXES = [("dark", re.compile(r"(?i)\bdark\b")),
        ("Spark", re.compile(r"(?i)\bspark\b")),
        ("DynType-XXXL", re.compile(r"(?i)\bxxxl\b|\bax ?5\b|\baccessibility (?:size|text)\b|\blargest\b")),
        ("Discreet", re.compile(r"(?i)\bdiscreet\b")),
        ("375pt", re.compile(r"(?<!\d)375(?:\s?pt)?(?!\d)")),
        ("ProMax", re.compile(r"(?i)\bpro ?max\b"))]
BASE_WORDS = re.compile(r"(?i)\b(light|calm|default)\b")
MVP = [("Onboarding", re.compile(r"(?i)onboard")),
       ("Today & Tasks", re.compile(r"(?i)\btoday\b|\btasks?\b")),
       ("Medication & Focus window", re.compile(r"(?i)medication|focus window")),
       ("Recovery & Support", re.compile(r"(?i)recovery|support")),
       ("Glanceables", re.compile(r"(?i)glanceable")),
       ("Watch", re.compile(r"(?i)\bwatch\b")),
       ("Settings & Privacy", re.compile(r"(?i)settings|privacy"))]
OTHER = [("components", re.compile(r"(?i)\bcomponents?\b")), ("foundations", re.compile(r"(?i)foundation")),
         ("lifestyles", re.compile(r"(?i)lifestyle")), ("v1", re.compile(r"(?i)\bv1\b")),
         ("future", re.compile(r"(?i)\bfuture\b")), ("prototype", re.compile(r"(?i)prototype")),
         ("handoff", re.compile(r"(?i)handoff")), ("cover", re.compile(r"(?i)\bcover\b"))]
MOTION = re.compile(r"(?i)anim|transition|motion|haptic|ring")
IPHONE_W = {320, 375, 390, 393, 402, 414, 428, 430, 440}
WATCH_W = range(150, 216)
DESC_LIMIT = 400
SCREENSHOT_CAP = 40


# ---------------------------------------------------------------- shared helpers (also used by extract_text.py)
def axes_of(name):
    return [a for a, rx in AXES if rx.search(name or "")]


def base_name(name):
    s = name or ""
    for _, rx in AXES:
        s = rx.sub(" ", s)
    s = BASE_WORDS.sub(" ", s)
    s = re.sub(r"[/\\()\[\],·—–\-_|:]+", " ", s)
    return re.sub(r"\s+", " ", s).strip().lower()


def base_of(page, frame, frames):
    """Id of the base-variant frame for a variant frame (same base name, no axes), or None."""
    want = base_name(frame["name"])
    for f in frames:
        if f["id"] != frame["id"] and not axes_of(f["name"]) and base_name(f["name"]) == want:
            return f["id"]
    return None


def kind_of(n):
    w, h = n.get("width") or 0, n.get("height") or 0
    name = n.get("name", "")
    if n["type"] == "SECTION":
        return "section"
    if n["type"] == "COMPONENT_SET":
        return "variant-set"
    if n["type"] == "COMPONENT":
        return "component"
    if int(w) in IPHONE_W and h >= 568:
        return "screen"
    if int(w) in WATCH_W and 170 <= h <= 260:
        return "watch"
    for kind, rx in (("widget", r"(?i)widget"), ("live-activity", r"(?i)live ?activity"), ("control", r"(?i)control"),
                     ("annotation", r"(?i)annotation|\bnotes?\b"), ("cover", r"(?i)\bcover\b"),
                     ("template", r"(?i)template"), ("sheet", r"(?i)\bsheet\b"), ("overlay", r"(?i)overlay|modal")):
        if re.search(rx, name):
            return kind
    return "other"


def page_category(name):
    """('mvp', index) / (other category, None) / ('unclassified', None)."""
    for cat, rx in OTHER:
        if rx.search(name):
            return cat, None
    for i, (_, rx) in enumerate(MVP):
        if rx.search(name):
            return "mvp", i
    return "unclassified", None


def norm_node(n):
    n = (n or "").strip().strip("`")
    return n if n in ("", "root") else n.replace("-", ":")


def parse_ledger(path, key):
    """Return (rows, epochs, problems). rows: dicts {tool,node,result,epoch,line}."""
    rows, epochs, probs = [], [], []
    if not path.exists():
        return rows, epochs, probs
    epoch = 0
    for i, line in enumerate(path.read_text(encoding="utf-8", errors="replace").split("\n"), 1):
        m = re.match(r"^EPOCH\s+(\d+)\s*\|.*?\|\s*cap\s+(\d+)", line)
        if m:
            epoch = int(m.group(1))
            epochs.append({"n": epoch, "cap": int(m.group(2)), "line": i, "reads": 0})
            continue
        if not re.match(r"^\|\s*\d+\s*\|", line):
            continue
        cells = [c.strip() for c in line.split("|")]
        if len(cells) < 11:
            probs.append((path, i, "LEDGER", f"row has {len(cells) - 2} cells; 04-T7 needs 12"))
            continue
        ts, tool, fkey, node, result = cells[2], cells[4], cells[5], norm_node(cells[6]), cells[9]
        if not TIME_OK.match(ts):
            probs.append((path, i, "TIME", f"timestamp '{ts}' lacks seconds or offset"))
        if epochs:
            epochs[-1]["reads"] += 1
        if fkey != key:
            continue
        res = result.split()[0].lower() if result else "pending"
        rows.append({"tool": tool, "node": node, "result": res, "epoch": epoch, "line": i})
    return rows, epochs, probs


def parse_coverage(path):
    """Return (set of unavailable tools, present?)."""
    if not path.exists():
        return set(), False
    off, header = set(), None
    for line in path.read_text(encoding="utf-8", errors="replace").split("\n"):
        if not line.startswith("|") or re.match(r"^\|[\s:|-]+\|?$", line.strip()):
            continue
        cells = [c.strip().strip("`*").strip() for c in line.strip().strip("|").split("|")]
        if header is None and any(re.search(r"(?i)avail|status|exposed|usable", c) for c in cells):
            header = cells
            continue
        col = next((j for j, c in enumerate(header or []) if re.search(r"(?i)avail|status|exposed|usable", c)), None)
        tool = cells[0].split("__")[-1]
        if col is not None and col < len(cells) and re.match(r"(?i)^(no|unavailable|not available|absent|blocked|denied)\b", cells[col]):
            off.add(tool)
    return off, True


def ambiguous_nodes(root):
    """Node ids listed after 'layout ambiguous' in docs/figma/analysis/*.md."""
    out = []
    adir = pathlib.Path(root) / "docs/figma/analysis"
    for p in sorted(adir.glob("*.md")) if adir.is_dir() else []:
        for line in p.read_text(encoding="utf-8", errors="replace").split("\n"):
            m = re.search(r"(?i)layout ambiguous[^:]*:(.*)$", line)
            if m:
                out += [(n, p) for n in ff.NODE_ID.findall(m.group(1))]
    return out


# ---------------------------------------------------------------- plan construction
class Plan:
    def __init__(self, ledger_rows):
        self.lines = []
        self.idx = {}
        for r in ledger_rows:
            self.idx.setdefault((r["tool"], r["node"]), []).append(r)

    def status(self, tool, node):
        rows = self.idx.get((tool, node), [])
        ok = [r for r in rows if r["result"] == "ok"]
        if ok:
            return "done", ok[0]["epoch"]
        if rows and rows[-1]["result"] in ("truncated", "error"):
            return "failed", None
        return "planned", None

    def add(self, tier, tool, node, page, frame, kind, axis, base, status=None):
        st, ep = self.status(tool, node)
        if status and st != "done":
            st = status
        self.lines.append({"tier": tier, "tool": tool, "node": node, "page": page, "frame": frame, "kind": kind,
                           "axis": axis, "base": base, "status": st, "epoch": ep})
        return st


def add_design(plan, p, tier, n, axis, base, status=None, label=None, depth=0):
    """Add a get_design_context line, expanding > 400-descendant or truncated frames to children."""
    tool = "get_design_context"
    name = label or n["name"]
    big = p.descendants(n["id"]) > DESC_LIMIT
    st, _ = plan.status(tool, n["id"])
    kids = [p.by_id[c] for c in p.children.get(n["id"], [])]
    if (big or st == "failed") and kids and depth < 6:
        if st in ("done", "failed"):
            plan.add(tier, tool, n["id"], p.name, f"{name} (read as a whole: {st})", kind_of(n), axis, base, status)
        for c in kids:
            add_design(plan, p, tier, c, axis, base, status,
                       f"{c['name']} (child of {n['name']}, parent: {n['id']}{', > 400 descendants' if big else ', truncated'})",
                       depth + 1)
        return
    plan.add(tier, tool, n["id"], p.name, name, kind_of(n), axis, base, status)


def build_plan(root, key, pages, ledger_rows, off, figjam, include_variants):
    plan = Plan(ledger_rows)
    cats = {p.slug: page_category(p.name) for p in pages}
    # T1
    plan.add("T1", "get_metadata", "root", "(file)", "root page listing", "other", "none", "n/a (file root)")
    for p in pages:
        plan.add("T1", "get_metadata", p.id, p.name, f"page {p.name}", "page", "none", "n/a (page node)")
    # T2
    var_pages = [p for p in pages if cats[p.slug][0] in ("foundations", "components")]
    if not var_pages:
        ranked = sorted(pages, key=lambda p: -(p.count("COMPONENT") + p.count("COMPONENT_SET")))
        var_pages = [p for p in ranked if p.count("COMPONENT") + p.count("COMPONENT_SET")][:2]
    for p in var_pages:
        plan.add("T2", "get_variable_defs", p.id, p.name, f"page {p.name}", "page", "none", "n/a (page node)")
    # T3, T4
    if figjam:
        bkey, _, bnode = figjam.partition(":")
        plan.add("T3", "get_figjam", norm_node(bnode) or "root", f"FigJam {bkey}", "flows board", "other", "none", "n/a (board)")
    plan.add("T4", "get_libraries", "root", "(file)", "library sources of instances", "other", "none", "n/a (file root)")
    # T5 / T7 / T8 / T9 / T10 / T11 per page
    t5_pages = sorted([p for p in pages if cats[p.slug][0] == "mvp"], key=lambda p: (cats[p.slug][1], pages.index(p)))
    t5_pages += [p for p in pages if cats[p.slug][0] in ("unclassified", "cover", "prototype", "handoff")]
    variant_lines = []
    for p in t5_pages + [p for p in pages if cats[p.slug][0] in ("lifestyles", "v1")]:
        tier = "T8" if cats[p.slug][0] in ("lifestyles", "v1") else "T5"
        frames = p.top_level_frames()
        seen_axes = set()
        for f in frames:
            ax = axes_of(f["name"])
            if not ax:
                add_design(plan, p, tier, f, "none", "yes")
                continue
            b = base_of(p, f, frames)
            base_txt = f"no (base {b})" if b else "no (base frame not found by name)"
            if ax[0] not in seen_axes:
                seen_axes.add(ax[0])
                variant_lines.append(("T9", p, f, "+".join(ax), base_txt, None))
            else:
                variant_lines.append(("T10", p, f, "+".join(ax), base_txt, None if include_variants else "skipped-variant"))
    for p in pages:
        if cats[p.slug][0] in ("components", "foundations"):
            for f in p.top_level_frames():
                add_design(plan, p, "T7", f, "none", "yes")
    # T6
    for p in pages:
        if cats[p.slug][0] == "prototype":
            plan.add("T6", "get_motion_context", p.id, p.name, f"page {p.name}", "page", "none", "n/a (page node)")
        for f in p.top_level_frames():
            if MOTION.search(f["name"]):
                ax = axes_of(f["name"])
                plan.add("T6", "get_motion_context", f["id"], p.name, f["name"], kind_of(f), "+".join(ax) or "none",
                         "no" if ax else "yes")
    for tier, p, f, ax, base_txt, st in variant_lines:
        add_design(plan, p, tier, f, ax, base_txt, st)
    # T11
    mvp_any = re.compile("|".join(rx.pattern.replace("(?i)", "") for _, rx in MVP), re.I)
    for p in pages:
        if cats[p.slug][0] == "future":
            for f in p.top_level_frames():
                if kind_of(f) in ("screen", "watch") and mvp_any.search(f["name"]):
                    add_design(plan, p, "T11", f, "+".join(axes_of(f["name"])) or "none", "yes")
    # T12
    shots = []
    by_node = {}
    for p in pages:
        for n in p.nodes:
            by_node[n["id"]] = p
    for nid, src in ambiguous_nodes(root):
        p = by_node.get(nid)
        if p is None:
            continue
        cur, sec = nid, None
        while cur and cur != p.id:
            node = p.by_id.get(cur)
            if node and node["type"] == "SECTION":
                sec = node
            cur = node["parentId"] if node else None
        target = (sec["id"], sec["name"]) if sec else (p.id, f"page {p.name}")
        if (target, p.name) not in shots:
            shots.append((target, p.name))
    for (tid, tname), pname in shots[:SCREENSHOT_CAP]:
        plan.add("T12", "get_screenshot", tid, pname, tname, "section" if not tname.startswith("page ") else "page",
                 "none", "n/a (layout ambiguous)")
    plan.lines = [l for l in plan.lines if l["tool"] not in off]
    return plan, max(0, len(shots) - SCREENSHOT_CAP)


def schedule(plan, epochs, reserve):
    cur = epochs[-1] if epochs else {"n": 1, "cap": 150, "reads": 0}
    capacity = max(0, cur["cap"] - reserve)
    left = max(0, capacity - cur["reads"])
    ep = cur["n"]
    for l in plan.lines:
        if l["status"] == "done":
            l["epoch"] = str(l["epoch"] or cur["n"])
        elif l["status"] == "skipped-variant":
            l["epoch"] = "unscheduled (metadata-only-variant)"
        else:
            while left == 0:
                ep += 1
                left = capacity
                if capacity == 0:
                    break
            l["epoch"] = str(ep)
            left -= 1
    return cur, capacity


def render(key, plan, cur, capacity, reserve, off, cov_present, dropped_shots, figjam):
    now = datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")
    tiers = ["T%d" % i for i in range(1, 13)]
    sts = ["planned", "done", "failed", "skipped-variant"]
    out = ["# FIGMA READ PLAN — generated by scripts/figma_read_plan.py (do not edit by hand; re-run after every batch)",
           f"Generated: {now} · File key: `{key}` · Cap: {cur['cap']} counted reads per epoch "
           f"({capacity} planned + {reserve} reserve) · Current epoch: {cur['n']} · Reads already in this epoch: {cur['reads']}",
           f"Lines: {len(plan.lines)} · " + " · ".join(f"{s}: {sum(1 for l in plan.lines if l['status'] == s)}" for s in sts),
           "Tool coverage: " + ("docs/figma/TOOL_COVERAGE.md" if cov_present else "TOOL_COVERAGE.md absent, every read tool assumed available")
           + (" · tools unavailable (lines omitted): " + ", ".join(f"`{t}`" for t in sorted(off)) if off else " · tools unavailable: none"),
           "T3: " + (f"FigJam board `{figjam}`" if figjam else "no FigJam board given (--figjam), no line planned")
           + f" · T12 screenshots over the cap of {SCREENSHOT_CAP}: {dropped_shots}", "",
           "## Totals per tier", "| Tier | Lines | planned | done | failed | skipped-variant |", "|---|---|---|---|---|---|"]
    for t in tiers:
        ls = [l for l in plan.lines if l["tier"] == t]
        out.append(f"| {t} | {len(ls)} | " + " | ".join(str(sum(1 for l in ls if l['status'] == s)) for s in sts) + " |")
    out += ["", "## Totals per epoch", "| Planned epoch | Lines | planned | done | failed | skipped-variant |", "|---|---|---|---|---|---|"]
    eps = []
    for l in plan.lines:
        if l["epoch"] not in eps:
            eps.append(l["epoch"])
    for e in sorted(eps, key=lambda x: (not x.isdigit(), int(x) if x.isdigit() else 0, x)):
        ls = [l for l in plan.lines if l["epoch"] == e]
        out.append(f"| {e} | {len(ls)} | " + " | ".join(str(sum(1 for l in ls if l['status'] == s)) for s in sts) + " |")
    out += ["", "## Plan", "| # | Tier | Tool | Node id | Page | Frame name | Kind | Variant axis | Base variant | Planned epoch | Status |",
            "|---|---|---|---|---|---|---|---|---|---|---|"]
    for i, l in enumerate(plan.lines, 1):
        frame = l["frame"].replace("|", "/")
        out.append(f"| {i} | {l['tier']} | {l['tool']} | {l['node']} | {l['page']} | {frame} | {l['kind']} | {l['axis']} | "
                   f"{l['base']} | {l['epoch']} | {l['status']} |")
    out += ["", "<!-- END OF FILE -->", ""]
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description="Generate docs/figma/read-plan.md.",
                                 formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    ap.add_argument("fileKey")
    ap.add_argument("--figjam", metavar="BOARDKEY:NODEID", help="plan the T3 get_figjam read of the flows board")
    ap.add_argument("--include-variants", action="store_true", help="plan T10 variants instead of skipped-variant")
    ap.add_argument("--reserve", type=int, default=30, help="reads per epoch kept in reserve (default 30)")
    ap.add_argument("--root", default=".", help="project root (default: current directory)")
    a = ap.parse_args()
    root = pathlib.Path(a.root).resolve()
    pages, code = fr.load(root, a.fileKey)
    if code:
        print("figma_read_plan: stopped (exit 2): fix the index problems above first")
        sys.exit(2)
    rows, epochs, probs = parse_ledger(root / "docs/figma/read-ledger.md", a.fileKey)
    off, cov = parse_coverage(root / "docs/figma/TOOL_COVERAGE.md")
    plan, dropped = build_plan(root, a.fileKey, pages, rows, off, a.figjam, a.include_variants)
    cur, capacity = schedule(plan, epochs, a.reserve)
    out = root / "docs/figma/read-plan.md"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(render(a.fileKey, plan, cur, capacity, a.reserve, off, cov, dropped, a.figjam), encoding="utf-8")
    for f in probs:
        ff.err(*f)
    counts = {s: sum(1 for l in plan.lines if l["status"] == s) for s in ("planned", "done", "failed", "skipped-variant")}
    print(f"figma_read_plan: wrote {ff.rel(out)}: {len(plan.lines)} lines · " +
          " · ".join(f"{k} {v}" for k, v in counts.items()) + f" · ledger problems {len(probs)}")
    sys.exit(1 if probs else 0)


if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
