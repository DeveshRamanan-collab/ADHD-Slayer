#!/usr/bin/env python3
"""check_facts.py [--root DIR] [--register PATH] [--manifest PATH] [--files F ...]

Cross-document fact check (F6; spec: prompts/06_SCRIPT_SPECS.md "check_facts.py").
Reads docs/FACT_REGISTER.md rows  FACT-nnn | key | canonical value | owning document | synonyms
(first cell may be **FACT-nnn**; synonyms separated by ';' or ','; 'none' allowed), then scans every
Markdown deliverable listed in docs/MANIFEST.md that exists (or --files) for lines that mention the key
or a synonym and state a different value.

How a "stated value" is found on a line that mentions the key (case-insensitive, whole words):
  table row   the cell right after the cell that equals the key/synonym is the stated value
  numeric     canonical value contains digits -> numbers/versions in the 80 characters after the
              mention are compared with the canonical numbers ("26" == "26.0")
  name        "<key> is|=|:|named|called <value>" -> <value> must start with the canonical value
Lines inside ```figma-copy / ```quote / ```output fences are skipped; the register itself is skipped.

Output: file:line:FACT: <FACT-id> '<key>' states '<found>' but canonical is '<value>' (owner <doc>)
Exit 1 on any mismatch; 2 when FACT_REGISTER.md or MANIFEST.md does not exist (or has no rows);
0 when clean.  Heuristic: it reports likely drift for the orchestrator to resolve (edit the
non-owning document, or supersede the fact with a D-nnn).
"""
import argparse, os, pathlib, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import validate_docs as V  # noqa: E402  (exempt_mask, EMPTY_CELL)

NUM = re.compile(r"\d+(?:\.\d+)*")


def norm_num(s):
    s = s.strip(".")
    while s.endswith(".0") and s.count(".") >= 1:
        s = s[:-2]
    return s


def cells(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def clean(c):
    return re.sub(r"[*`\"“”]", "", c).strip()


def load_register(path):
    facts = []
    for i, l in enumerate(path.read_text(encoding="utf-8").split("\n"), 1):
        if not l.strip().startswith("|"):
            continue
        cs = cells(l)
        m = re.match(r"^\**(FACT-\d{3})\**$", cs[0]) if cs else None
        if not m or len(cs) < 4:
            continue
        syn = []
        if len(cs) >= 5 and clean(cs[4]).lower() not in ("none", "", "n/a") and not clean(cs[4]).lower().startswith("n/a ("):
            syn = [clean(s) for s in re.split(r"[;,]", cs[4]) if clean(s)]
        facts.append({"id": m.group(1), "key": clean(cs[1]), "value": clean(cs[2]), "owner": clean(cs[3]),
                      "syn": syn, "line": i})
    return facts


def manifest_files(root, man):
    out = []
    for l in man.read_text(encoding="utf-8").split("\n"):
        m = re.match(r"^\|\s*((?:docs/|CLAUDE\.md|scripts/)[^\s|]*)\s*\|", l)
        if m and m.group(1).endswith(".md"):
            p = root / m.group(1)
            if p.exists():
                out.append(p)
    return out


def check_line(fact, raw):
    """Return the conflicting stated value, or None."""
    names = [fact["key"]] + fact["syn"]
    canon = fact["value"]
    canon_nums = set(norm_num(n) for n in NUM.findall(canon))
    low = raw.lower()
    hit = None
    for n in names:
        m = re.search(r"(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_])" % re.escape(n.lower()), low)
        if m:
            hit = (n, m); break
    if not hit:
        return None
    name, m = hit
    if raw.strip().startswith("|"):
        cs = [clean(c) for c in cells(raw)]
        for j, c in enumerate(cs[:-1]):
            if c.lower() == name.lower():
                stated = cs[j + 1]
                if stated in V.EMPTY_CELL:
                    return None
                if canon_nums:
                    got = set(norm_num(x) for x in NUM.findall(stated))
                    if got and not (got & canon_nums):
                        return stated
                    return None
                if canon.lower() not in stated.lower():
                    return stated
                return None
    tail = raw[m.end(): m.end() + 80]
    tail = re.split(r"(?<=[a-z0-9)])\.\s|\|", tail)[0]
    if canon_nums:
        got = [norm_num(x) for x in NUM.findall(tail)]
        if got and not (set(got) & canon_nums):
            return " ".join(NUM.findall(tail))
        return None
    mm = re.match(r"\s*(?:is|are|=|:|named|called|—|-)\s*[\"“`*]*([A-Za-z0-9][A-Za-z0-9 ._/+-]{0,60})", tail)
    if mm:
        stated = mm.group(1).strip()
        if not stated.lower().startswith(canon.lower()) and not canon.lower().startswith(stated.lower()):
            return stated
    return None


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".")
    ap.add_argument("--register", default="docs/FACT_REGISTER.md")
    ap.add_argument("--manifest", default="docs/MANIFEST.md")
    ap.add_argument("--files", nargs="*", default=None, help="scan these files instead of the manifest")
    a = ap.parse_args()
    root = pathlib.Path(a.root).resolve()
    reg = root / a.register
    if not reg.exists():
        print("%s:0:MISSING: fact register does not exist yet (written in Phase 6+); nothing to check" % a.register)
        sys.exit(2)
    facts = load_register(reg)
    if not facts:
        print("%s:0:EMPTY: no FACT-nnn rows found" % a.register); sys.exit(2)
    if a.files is not None:
        files = [root / f for f in a.files]
    else:
        man = root / a.manifest
        if not man.exists():
            print("%s:0:MISSING: manifest does not exist" % a.manifest); sys.exit(2)
        files = manifest_files(root, man)
    errs = []
    scanned = 0
    for f in files:
        if not f.exists():
            print("%s:0:MISSING: file does not exist (skipped)" % f); continue
        if f.resolve() == reg.resolve():
            continue
        scanned += 1
        lines = f.read_text(encoding="utf-8", errors="replace").split("\n")
        masked = V.exempt_mask(lines)
        rel = os.path.relpath(str(f), str(root))
        for i, raw in enumerate(lines, 1):
            if masked[i - 1][1]:
                continue
            for fact in facts:
                bad = check_line(fact, raw)
                if bad is not None:
                    errs.append("%s:%d:FACT: %s '%s' states '%s' but canonical is '%s' (owner %s)"
                                % (rel, i, fact["id"], fact["key"], bad, fact["value"], fact["owner"]))
    for e in errs:
        print(e)
    print("check_facts: %d facts, %d files scanned, %d mismatches" % (len(facts), scanned, len(errs)))
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
