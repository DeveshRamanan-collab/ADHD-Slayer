#!/usr/bin/env python3
"""validate_parts.py <DOC>   Runs validate_docs.py's per-file rules (END, PHRASE, PLACE, TIME, CELL, IDFMT, EV) on every
docs/parts/<DOC>/*.md, which validate_docs.py excludes by design. Prints file:line:RULE: message; exit 1 on any failure."""
import sys, pathlib, importlib.util
def main():
    if len(sys.argv) != 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__); sys.exit(0 if len(sys.argv) > 1 else 2)
    root = pathlib.Path(__file__).resolve().parent.parent
    spec = importlib.util.spec_from_file_location("vd", root / "scripts/validate_docs.py"); vd = importlib.util.module_from_spec(spec); spec.loader.exec_module(vd)
    vd.EXCL = tuple(e for e in vd.EXCL if e != "docs/parts/")
    parts = sorted((root / "docs/parts" / sys.argv[1]).glob("*.md")); fails = 0
    for p in parts:
        errs = vd.check(p, False)[0]
        for f, l, r, m in errs: print(f"{f}:{l}:{r}: {m}")
        fails += len(errs)
    print(f"validate_parts: {len(parts)} parts, {fails} failures"); sys.exit(1 if fails else 0)
if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
