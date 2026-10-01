#!/usr/bin/env python3
"""design_doc_xref.py [--root DIR] [--sources PATH_OR_GLOB ...] [--all] [--strict]

Design-document cross-reference (spec: prompts/06_SCRIPT_SPECS.md "design_doc_xref.py"; used for
docs/RECONCILIATION.md, docs/DESIGN_SYSTEM.md and gate G2 item 6).

Sources: docs/design/handoff.md and docs/design/DESIGN_SPEC.md (whichever exist).  When neither exists
(B-001), the D-005 substitutes are read instead: docs/build-spec/*.md and design/figma/README.md.
--sources overrides both (paths or globs relative to --root).  The sources used are always printed.

Extraction (every fenced code region skipped): heading text, table first cells (header rows skipped) and
backticked identifiers.  Each name gets a Kind (a heading's kind comes from its shape or its parent
headings, never from its own words; a heading made only of category words, such as "Colour tokens" or "States",
is a section title, not a name):
  token      shape like color.bg.primary / spacing/4 / --radius / $accent, or under a heading about tokens,
             colour, palette, spacing, typography, font, radius, corner, shadow, elevation, motion,
             animation, duration, easing, opacity or variables
  component  PascalCase shape (TaskCard), or under a heading about components, views, controls, buttons,
             cards, sheets, cells, rows, widgets, toolbars, tab bars, navigation, chips or rings
  state      a state word (default, empty, loading, error, pressed, disabled, selected, focused, active,
             offline, denied, on, off, expanded, collapsed), or under a heading about states, variants
             or modes
  other      anything else; listed only with --all
Look-up (all under --root): every docs/figma/raw/**/nodes.json (node names), the variables cache
(docs/figma/raw/**/get_variable_defs/* and docs/figma/raw/**/variables*.json: JSON keys and "name"
values, including JSON held in an MCP {"type":"text","text":...} wrapper) and docs/figma/text-layers.csv
(text column).  Match: exact (case-sensitive, whole name or a separator-bounded part of one),
case-insensitive, or normalised (case-insensitive with . / - _ and spaces treated as one separator).

Output: a Markdown table on stdout (# | Name | Kind | Defined at | Found | Where | Match) followed by
the unfound count; one line per unfound item on stderr as file:line:XREF-UNFOUND: message.
Rules: XREF-UNFOUND (unfound item; a failure only with --strict), MISSING (no source document; exit 2).
Exit 2 when no source document exists; 1 with --strict and any unfound item; 0 otherwise.
"""
import argparse, csv, glob, json, pathlib, re, sys

FENCE = "`" * 3
TOKEN_CTX = re.compile(r"token|colou?r|palette|spacing|typograph|type scale|font|radius|radii|corner|shadow|elevation|motion|animation|duration|easing|opacity|variable", re.I)
COMP_CTX = re.compile(r"component|\bviews?\b|control|button|\bcards?\b|sheet|\bcells?\b|\brows?\b|widget|toolbar|tab bar|navigation|\bchips?\b|\brings?\b", re.I)
STATE_CTX = re.compile(r"\bstates?\b|variant|\bmodes?\b", re.I)
STATE_WORDS = {"default", "empty", "loading", "error", "pressed", "disabled", "selected", "focused", "active",
               "offline", "denied", "on", "off", "expanded", "collapsed", "hover"}
TOKEN_SHAPE = re.compile(r"^(--|\$)?[a-z][\w-]*([./][\w-]+)+$|^--[a-z][\w-]+$|^\$[a-z][\w-]+$")
PASCAL = re.compile(r"^[A-Z][a-z0-9]+(?:[A-Z][a-z0-9]+)+$")
SEP = re.compile(r"[\s./_\-]+")
RANK = {"normalised": 1, "case-insensitive": 2, "exact": 3}


def kind_of(name, ctx):
    n = name.strip()
    if TOKEN_SHAPE.match(n):
        return "token"
    if PASCAL.match(n):
        return "component"
    if n.lower() in STATE_WORDS:
        return "state"
    for rx, k in ((STATE_CTX, "state"), (TOKEN_CTX, "token"), (COMP_CTX, "component")):
        if rx.search(ctx):
            return k
    return "other"


def split(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def is_sep(line):
    return bool(re.match(r"^\|[\s:\-|]+\|?$", line.strip()))


def clean(s):
    return re.sub(r"[*`]", "", s).strip().strip('"').strip()


def extract(path, rel):
    """[(name, kind, 'rel:line')] from headings, table first cells and backticked identifiers."""
    lines = path.read_text(encoding="utf-8").split("\n"); out = []; heads = {}; fence = False
    for i, l in enumerate(lines, 1):
        if re.match(r"^\s*" + FENCE, l):
            fence = not fence; continue
        if fence:
            continue
        h = re.match(r"^(#{1,6})\s+(.+?)\s*#*\s*$", l)
        if h:
            lvl = len(h.group(1)); text = clean(h.group(2))
            parent = " ".join(heads[k] for k in sorted(heads) if k < lvl)
            heads = {k: v for k, v in heads.items() if k < lvl}; heads[lvl] = text
            residue = [w for w in re.findall(r"\w+", STATE_CTX.sub(" ", TOKEN_CTX.sub(" ", COMP_CTX.sub(" ", text))))
                       if w.lower() not in ("and", "the", "of", "for", "s", "es")]
            if 0 < len(text.split()) <= 6 and (residue or TOKEN_SHAPE.match(text) or PASCAL.match(text)):
                out.append((text, kind_of(text, parent), f"{rel}:{i}"))  # a heading's own words never set its kind
            continue
        ctx = " ".join(heads[k] for k in sorted(heads))
        if l.strip().startswith("|") and not is_sep(l):
            nxt = lines[i] if i < len(lines) else ""
            if not is_sep(nxt):
                c0 = clean(split(l)[0])
                if c0 and len(c0) <= 60 and len(c0.split()) <= 6:
                    out.append((c0, kind_of(c0, ctx), f"{rel}:{i}"))
        for m in re.finditer(r"`([^`\n]{1,60})`", l):
            b = m.group(1).strip()
            if not b or len(b.split()) > 4 or re.search(r"\.(md|swift|json|py|sh|pdf|csv|txt|ts|js|tsx|html|css|ya?ml|plist|xcstrings|strings|png|svg)$|^(docs|scripts|prompts|app|design)/|[(){};=]", b):
                continue
            out.append((b, kind_of(b, ctx), f"{rel}:{i}"))
    return out


def names_from_json(obj, acc):
    if isinstance(obj, dict):
        for k, v in obj.items():
            acc.add(str(k))
            if k == "name" and isinstance(v, str):
                acc.add(v)
            if k == "text" and isinstance(v, str):
                try:
                    names_from_json(json.loads(v), acc)
                except ValueError:
                    for l in v.split("\n"):
                        m = re.match(r"^\s*[-*]?\s*[\"']?([A-Za-z$-][\w ./$-]*?)[\"']?\s*:", l)
                        if m:
                            acc.add(m.group(1))
            else:
                names_from_json(v, acc)
    elif isinstance(obj, list):
        for v in obj:
            names_from_json(v, acc)


def load_cache(root):
    nodes = set(); variables = set(); texts = set(); used = []
    raw = root / "docs/figma/raw"
    for p in sorted(raw.rglob("nodes.json")) if raw.exists() else []:
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
        except ValueError:
            continue
        for n in data.get("nodes", []) if isinstance(data, dict) else []:
            if n.get("name"):
                nodes.add(n["name"])
        used.append(str(p.relative_to(root)))
    vfiles = (sorted(f for f in raw.rglob("*") if f.is_file() and ("get_variable_defs" in f.parts or re.match(r"variables.*\.json$", f.name)))
              if raw.exists() else [])
    for p in vfiles:
        txt = p.read_text(encoding="utf-8", errors="replace")
        try:
            names_from_json(json.loads(txt), variables)
        except ValueError:
            names_from_json({"text": txt}, variables)
        used.append(str(p.relative_to(root)))
    tl = root / "docs/figma/text-layers.csv"
    if tl.exists():
        with tl.open(encoding="utf-8", newline="") as f:
            for row in csv.DictReader(f):
                if row.get("text"):
                    texts.add(row["text"])
        used.append(str(tl.relative_to(root)))
    return {"nodes.json": nodes, "variables": variables, "text-layers.csv": texts}, used


def match(name, pool):
    """Return 'exact' | 'case-insensitive' | 'normalised' | None."""
    if not name.strip():
        return None
    bound = r"(?<![A-Za-z0-9])%s(?![A-Za-z0-9])"
    ex = re.compile(bound % re.escape(name)); ci = re.compile(bound % re.escape(name), re.I)
    nn = SEP.sub(" ", name).strip().lower(); nr = re.compile(bound % re.escape(nn))
    best = None
    for s in pool:
        if s == name or ex.search(s):
            return "exact"
        if best is None and (s.lower() == name.lower() or ci.search(s)):
            best = "case-insensitive"
        if best is None and nn and nr.search(SEP.sub(" ", s).lower()):
            best = "normalised"
    return best


def esc(s):
    return s.replace("|", "\\|")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".", help="project or fixture root (default: .)")
    ap.add_argument("--sources", nargs="+", help="design documents (paths or globs relative to --root)")
    ap.add_argument("--all", action="store_true", help="also list names whose kind is 'other'")
    ap.add_argument("--strict", action="store_true", help="exit 1 when any item is unfound")
    a = ap.parse_args()
    root = pathlib.Path(a.root)
    if a.sources:
        srcs = []
        for s in a.sources:
            hits = sorted(glob.glob(str(root / s)))
            srcs += [pathlib.Path(h) for h in hits] if hits else [root / s]
        why = "--sources"
    else:
        srcs = [root / p for p in ("docs/design/handoff.md", "docs/design/DESIGN_SPEC.md") if (root / p).exists()]
        why = "docs/design"
        if not srcs:
            srcs = sorted((root / "docs/build-spec").glob("*.md")) + ([root / "design/figma/README.md"] if (root / "design/figma/README.md").exists() else [])
            why = "substitute for docs/design/handoff.md and docs/design/DESIGN_SPEC.md (D-005, B-001)"
    present = [p for p in srcs if p.exists()]
    for p in srcs:
        if not p.exists():
            print(f"{p.relative_to(root) if str(p).startswith(str(root)) else p}:0:MISSING: source not found", file=sys.stderr)
    if not present:
        print("design_doc_xref: no source document found", file=sys.stderr); sys.exit(2)
    rels = [str(p.relative_to(root)) for p in present]
    print(f"SOURCES ({why}): {', '.join(rels)}")
    pools, used = load_cache(root)
    print(f"LOOK-UP: {', '.join(used) if used else 'none cached yet (every item is unfound)'}")
    items = []; seen = set()
    for p, r in zip(present, rels):
        for name, kind, at in extract(p, r):
            if kind == "other" and not a.all:
                continue
            if (name, kind) in seen:
                continue
            seen.add((name, kind)); items.append((name, kind, at))
    print("")
    print("| # | Name | Kind | Defined at | Found | Where | Match |")
    print("|---|---|---|---|---|---|---|")
    unfound = []; per = {}
    for n, (name, kind, at) in enumerate(items, 1):
        where = []; how = None
        for pool_name, pool in pools.items():
            m = match(name, pool)
            if m:
                where.append(pool_name)
                if how is None or RANK[m] > RANK[how]:
                    how = m
        found = "yes" if where else "no"
        print(f"| {n} | {esc(name)} | {kind} | {at} | {found} | {', '.join(where) if where else 'not found'} | {how or 'none'} |")
        if not where:
            unfound.append((name, kind, at)); per[kind] = per.get(kind, 0) + 1
    print("")
    print(f"UNFOUND: {len(unfound)} of {len(items)} ({', '.join(f'{k} {v}' for k, v in sorted(per.items())) or 'none'})")
    for name, kind, at in unfound:
        print(f"{at}:XREF-UNFOUND: {kind} '{name}' not found in nodes.json names, the variables cache or text-layers.csv", file=sys.stderr)
    sys.exit(1 if (a.strict and unfound) else 0)


if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
