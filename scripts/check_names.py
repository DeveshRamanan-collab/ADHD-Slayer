#!/usr/bin/env python3
"""check_names.py [--root DIR] [--reserved PATH] [--docs PATH ...]

Name-collision check (F30; spec: prompts/06_SCRIPT_SPECS.md "check_names.py"; naming rule:
prompts/01_MASTER_PLANNING_PROMPT.md Phase 7 decision 9).

Reads every DATA-/ENG-/ARCH- definition (heading "### <ID> <name> ..." or table row
"| **<ID>** | <name> | ...") in docs/DATA_MODEL.md, docs/ENGINE_SPEC.md and docs/ARCHITECTURE.md,
takes its name (first backticked identifier on the line if any, else the text after the id / the
second cell, cut at the first separator), and compares it case-insensitively with every reserved
simple name in docs/RESERVED_NAMES.md (first table cells and backticked identifiers in list items).
A collision is an exact simple-name match of the whole name or of its first identifier word.

Output: file:line:NAME: <ID> name '<name>' collides with reserved '<reserved>' -> use '<alternative>'
The alternative is the RESERVED_NAMES.md "alternative"/"suggested" column when present, else
'Planner' + the name.
Exit 1 on any collision; 2 when RESERVED_NAMES.md or a defining document does not exist yet; 0 clean.
"""
import argparse, os, pathlib, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import validate_docs as V  # noqa: E402

DEFAULT_DOCS = ["docs/DATA_MODEL.md", "docs/ENGINE_SPEC.md", "docs/ARCHITECTURE.md"]
HDEF = re.compile(r"^#{2,4}\s+((?:DATA|ENG|ARCH)-\d{4})\b(.*)$")
CDEF = re.compile(r"^\|\s*\*\*((?:DATA|ENG|ARCH)-\d{4})\*\*\s*\|(.*)$")
IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


def load_reserved(path):
    names = {}
    header = None
    for l in path.read_text(encoding="utf-8").split("\n"):
        s = l.strip()
        if s.startswith("|"):
            cs = [c.strip() for c in s.strip("|").split("|")]
            if re.match(r"^[:\- ]+$", "".join(cs)):
                continue
            if header is None:
                header = [c.lower() for c in cs]
                continue
            n = re.sub(r"[*`]", "", cs[0]).strip()
            alt = None
            for j, h in enumerate(header):
                if ("alternative" in h or "suggest" in h or "use instead" in h) and j < len(cs):
                    alt = re.sub(r"[*`]", "", cs[j]).strip() or None
            if IDENT.fullmatch(n):
                names.setdefault(n.lower(), (n, alt))
        else:
            header = None
            if re.match(r"^\s*[-*]\s", l):
                for b in re.findall(r"`([A-Za-z_][A-Za-z0-9_]*)`", l):
                    names.setdefault(b.lower(), (b, None))
    return names


def def_name(rest, is_table):
    b = re.search(r"`([A-Za-z_][A-Za-z0-9_.]*)`", rest)
    if b:
        return b.group(1).split(".")[-1]
    if is_table:
        cell = rest.split("|")[0]
    else:
        cell = rest
    cell = re.sub(r"[*`]", "", cell).strip()
    cell = re.split(r"\s[—–-]\s|[:·(|]", cell)[0].strip(" -—–")
    return cell


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".")
    ap.add_argument("--reserved", default="docs/RESERVED_NAMES.md")
    ap.add_argument("--docs", nargs="*", default=DEFAULT_DOCS)
    a = ap.parse_args()
    root = pathlib.Path(a.root).resolve()
    missing = [p for p in [a.reserved] + a.docs if not (root / p).exists()]
    if missing:
        for p in missing:
            print("%s:0:MISSING: input document does not exist yet" % p)
        print("check_names: cannot run until every input exists (%d missing)" % len(missing))
        sys.exit(2)
    reserved = load_reserved(root / a.reserved)
    if not reserved:
        print("%s:0:EMPTY: no reserved names parsed" % a.reserved); sys.exit(2)
    errs = []; ndefs = 0
    for d in a.docs:
        lines = (root / d).read_text(encoding="utf-8").split("\n")
        masked = V.exempt_mask(lines)
        for i, raw in enumerate(lines, 1):
            if masked[i - 1][1]:
                continue
            m = HDEF.match(raw) or CDEF.match(raw)
            if not m:
                continue
            ndefs += 1
            ident, rest = m.group(1), m.group(2)
            name = def_name(rest, raw.lstrip().startswith("|"))
            if not name:
                continue
            cands = [name]
            w = IDENT.match(name)
            if w and w.group(0) != name:
                cands.append(w.group(0))
            for c in cands:
                r = reserved.get(c.lower())
                if r:
                    alt = r[1] or ("Planner" + re.sub(r"\W", "", name[:1].upper() + name[1:]))
                    errs.append("%s:%d:NAME: %s name '%s' collides with reserved '%s' -> use '%s'"
                                % (d, i, ident, name, r[0], alt))
                    break
    for e in errs:
        print(e)
    print("check_names: %d definitions, %d reserved names, %d collisions" % (ndefs, len(reserved), len(errs)))
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
