#!/usr/bin/env python3
"""assemble_docs.py <DOC> [--order manifest|pages] [--root DIR] [--out PATH] [--dry-run]

Concatenates docs/parts/<DOC>/<nn>-*.md into docs/<DOC>.md (spec: prompts/06_SCRIPT_SPECS.md
"assemble_docs.py"; OM-2/OM-3 of prompts/01_MASTER_PLANNING_PROMPT.md: merges are concatenations,
never re-typed text).

Order
  default            numeric order of the <nn> prefix; for DOC=FIGMA_AUDIT the page order from
                     docs/figma/raw/*/<page-slug>/nodes.json is used for parts named <nn>-<page-slug>.md
                     (page order = the nodes.json "pageIndex" key when present, else the part's <nn>)
  --order manifest   force plain numeric order (also for FIGMA_AUDIT)
  --order pages      force page order (any DOC)

Summary
  A part named 00-summary.md may contain the line {{SUMMARY}}; it is replaced by a generated table
  (part file, lines, headings, id definitions, first heading).

Refusals (exit 1, file:line:RULE: message)
  PARTIAL   a *.PARTIAL.md file exists in the parts folder
  END       a part lacks its own <!-- END OF FILE --> marker
  NAME      a .md file in the parts folder does not match <nn>-<name>.md
Exit 2: parts folder missing or empty.  Exit 0: written (path printed).
Each part's own end marker is removed; one marker is appended at the end of the assembled file.
"""
import argparse, json, os, pathlib, re, sys

END = "<!-- END OF FILE -->"
PART_RE = re.compile(r"^(\d+)-(.+)\.md$")
DEF_RE = re.compile(r"^(?:#{2,4}\s+([A-Z][A-Z-]*-\d{2,4})\b|\|\s*\*\*([A-Z][A-Z-]*-\d{2,4})\*\*\s*\|)")


def page_order(root):
    """slug -> sort key from every docs/figma/raw/<key>/<slug>/nodes.json."""
    order = {}
    for p in sorted((root / "docs/figma/raw").glob("*/*/nodes.json")):
        slug = p.parent.name
        idx = None
        try:
            data = json.loads(p.read_text(encoding="utf-8"))
            if isinstance(data, dict) and isinstance(data.get("pageIndex"), int):
                idx = data["pageIndex"]
        except Exception:
            idx = None
        order[slug] = idx
    return order


def summarise(parts):
    rows = ["| Part | Lines | Headings | Id definitions | First heading |", "|---|---|---|---|---|"]
    for p, text in parts:
        lines = text.split("\n")
        heads = [l for l in lines if re.match(r"^#{1,6}\s", l)]
        defs = sum(1 for l in lines if DEF_RE.match(l))
        first = heads[0].lstrip("#").strip().replace("|", "/") if heads else "N/A (part has no heading)"
        rows.append("| %s | %d | %d | %d | %s |" % (p.name, len(lines), len(heads), defs, first))
    return "\n".join(rows)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("doc", help="document name without .md, e.g. PRODUCT_SPEC")
    ap.add_argument("--order", choices=["manifest", "pages"], default=None)
    ap.add_argument("--root", default=".", help="project root (default: current directory)")
    ap.add_argument("--out", default=None, help="output path (default: <root>/docs/<DOC>.md)")
    ap.add_argument("--dry-run", action="store_true", help="check and print the order; write nothing")
    a = ap.parse_args()
    root = pathlib.Path(a.root).resolve()
    pdir = root / "docs/parts" / a.doc
    if not pdir.is_dir():
        print("%s:0:MISSING: parts folder does not exist" % pdir); sys.exit(2)
    errs = []
    for p in sorted(pdir.iterdir()):
        if p.name.endswith(".PARTIAL.md"):
            errs.append((p, 0, "PARTIAL", "part is unfinished (.PARTIAL.md); finish it before assembling"))
    cands = []
    for p in sorted(pdir.glob("*.md")):
        if p.name.endswith(".PARTIAL.md"):
            continue
        m = PART_RE.match(p.name)
        if not m:
            errs.append((p, 0, "NAME", "part name does not match <nn>-<name>.md")); continue
        cands.append((int(m.group(1)), m.group(2), p))
    if not cands and not errs:
        print("%s:0:MISSING: no parts found" % pdir); sys.exit(2)
    texts = {}
    for n, slug, p in cands:
        t = p.read_text(encoding="utf-8")
        if END not in t[-400:]:
            errs.append((p, len(t.split("\n")), "END", "part lacks its own %s" % END))
        texts[p] = t
    if errs:
        for p, l, r, m in errs:
            print("%s:%d:%s: %s" % (p.relative_to(root) if str(p).startswith(str(root)) else p, l, r, m))
        print("assemble_docs: refused (%d problems); nothing written" % len(errs)); sys.exit(1)
    use_pages = (a.order == "pages") or (a.order is None and a.doc == "FIGMA_AUDIT")
    if use_pages:
        po = page_order(root)
        def key(c):
            n, slug, p = c
            if slug == "summary" or n == 0:
                return (0, -1, n)
            if slug in po:
                return (1, po[slug] if po[slug] is not None else n, n)
            return (2, n, n)
        cands.sort(key=key)
    else:
        cands.sort(key=lambda c: (c[0], c[1]))
    ordered = [(p, texts[p]) for n, s, p in cands]
    out_parts = []
    for p, t in ordered:
        body = t.rstrip()
        if body.endswith(END):
            body = body[: -len(END)].rstrip()
        if p.name == "00-summary.md" and "{{SUMMARY}}" in body:
            body = body.replace("{{SUMMARY}}", summarise(ordered))
        out_parts.append(body)
    result = "\n\n".join(out_parts) + "\n\n" + END + "\n"
    out = pathlib.Path(a.out) if a.out else root / "docs" / ("%s.md" % a.doc)
    print("order: " + ", ".join(p.name for p, _ in ordered))
    if a.dry_run:
        print("assemble_docs: dry run; %d parts; nothing written" % len(ordered)); sys.exit(0)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(result, encoding="utf-8")
    print("assemble_docs: wrote %s (%d parts, %d lines)" % (out, len(ordered), result.count("\n")))
    sys.exit(0)


if __name__ == "__main__":
    main()
