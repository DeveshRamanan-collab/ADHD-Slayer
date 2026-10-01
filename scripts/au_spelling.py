#!/usr/bin/env python3
"""au_spelling.py [--root DIR] [--strict] <paths...>

Australian-English spelling check (spec: prompts/06_SCRIPT_SPECS.md "au_spelling.py"; register F29 / RL-5).
Scans prose outside code identifiers, inline backticks and fenced code (every fence is skipped here; the
masking mirrors scripts/validate_docs.py exempt_mask, which only exempts figma-copy/quote/output fences)
for the US-spelling list:

  color  behavior  organize  organization  center  license (as a noun)  favorite  gray  analyze
  customize  optimize  catalog  canceled  program (for a schedule)  jewelry  liter  meter (unit)  mom  math

with inflections (colors, colored, behaviors, organized, centered, favorites, analyzed, customizing,
optimizes, catalogs, canceling ...).  Code identifiers (camelCase, snake_case, dotted.names, words with
digits, URLs, file paths) are removed before matching.  Heuristics for the context-dependent words:
  license  flagged when used as a noun: after a/an/the/your/my/our/their/this/that/driver's/software/
           open-source, or before agreement/key/terms/fee/holder/number/plate/text
  program  flagged when used for a schedule: within three words of schedule/daily/weekly/exercise/
           training/fitness/event/tv/study/course/routine/day/week/session/plan
  meter    flagged when a unit: after a number, or after square/cubic/per/a/one, and kilometer/
           centimeter/millimeter always
Paths may be files or directories (recursive: .md .txt .strings .stringsdict .xcstrings .json .csv).
A UI string file is .strings/.stringsdict/.xcstrings/.csv/.json, or any file whose name contains
"copy", "strings" or "localizable"; every other file is a document.

Rules (file:line:RULE: message)
  AUSPELL       US spelling in a UI string file, or in a document with --strict      (failure)
  AUSPELL-WARN  US spelling in a document without --strict                           (warning only)
  DISCREET      "Discrete mode" / "Discrete variant" anywhere, code and backticks included (always a
                failure: the product word is "Discreet")
Exit 1 on any failure; 2 when a path does not exist; 0 otherwise (warnings do not fail).
--root DIR resolves relative paths against DIR (default: the current directory).
"""
import argparse, pathlib, re, sys

US = [  # (regex, AU suggestion)
    (r"color(s|ed|ing|ful|less)?", "colour"),
    (r"behavior(s|al|ally)?", "behaviour"),
    (r"organiz(e|es|ed|er|ers|ing)", "organise"),
    (r"organization(s|al)?", "organisation"),
    (r"center(s|ed|ing)?", "centre"),
    (r"favorite(s|d)?", "favourite"),
    (r"gray(s|ed|ish)?", "grey"),
    (r"analyz(e|es|ed|er|ers|ing)", "analyse"),
    (r"customiz(e|es|ed|ing|ation|ations)", "customise"),
    (r"optimiz(e|es|ed|er|ing|ation|ations)", "optimise"),
    (r"catalog(s|ed|ing)?", "catalogue"),
    (r"cancel(ed|ing)", "cancelled/cancelling"),
    (r"jewelry", "jewellery"),
    (r"liter(s)?", "litre"),
    (r"(kilo|centi|milli)meter(s)?", "metre"),
    (r"moms?", "mum"),
    (r"math", "maths"),
]
US_RE = [(re.compile(r"\b" + p + r"\b", re.I), s) for p, s in US]
LICENSE = re.compile(r"\b(?:(?:a|an|the|your|my|our|their|this|that|driver's|drivers|software|open-source|open source)\s+license(s)?\b|\blicense(s)?\s+(?:agreement|key|terms|fee|holder|number|plate|text))", re.I)
PROGRAM = re.compile(r"\bprograms?\b", re.I)
PROGRAM_CTX = re.compile(r"\b(schedule|daily|weekly|exercise|training|fitness|event|tv|study|course|routine|day|week|session|plan)\b", re.I)
METER = re.compile(r"(?:\b\d+(?:\.\d+)?\s*|\b(?:square|cubic|per|a|one)\s+)(meters?)\b", re.I)
DISCRETE = re.compile(r"\bdiscrete[\s-]+(mode|variants?)\b", re.I)
FENCE = "`" * 3
IDENT = re.compile(r"https?://\S+|(?:[\w.-]+/)+[\w.-]+|\b\w*[a-z][A-Z]\w*\b|\b\w+_\w+\b|\b\w+(?:\.\w+)+\b|\b(?=\w*[A-Za-z])(?=\w*\d)\w+\b")
UI_SUFFIX = {".strings", ".stringsdict", ".xcstrings", ".csv", ".json"}
SCAN_SUFFIX = {".md", ".txt"} | UI_SUFFIX


def mask_lines(lines):
    """Per line: prose with fenced code (any info string), inline backticks and code identifiers removed."""
    out = []; fence = False
    for l in lines:
        if re.match(r"^\s*" + FENCE, l):
            fence = not fence; out.append(""); continue
        if fence:
            out.append(""); continue
        l = re.sub(r"`[^`\n]*`", " ", l)
        out.append(IDENT.sub(" ", l))
    return out


def find_us(text):
    """Return [(word, suggestion)] US spellings in one masked prose string (also used by copy_scan.py)."""
    hits = []
    for rx, sug in US_RE:
        for m in rx.finditer(text):
            hits.append((m.group(0), sug))
    for m in LICENSE.finditer(text):
        hits.append((m.group(0), "licence (noun)"))
    for m in PROGRAM.finditer(text):
        window = " ".join(re.findall(r"\w+", text[max(0, m.start() - 40):m.end() + 40]))
        words = window.split(); idx = [i for i, w in enumerate(words) if w.lower().startswith("program")]
        near = any(PROGRAM_CTX.match(words[j]) for i in idx for j in range(max(0, i - 3), min(len(words), i + 4)) if j != i)
        if near:
            hits.append((m.group(0), "programme (schedule)"))
    for m in METER.finditer(text):
        hits.append((m.group(1), "metre (unit)"))
    return hits


def is_ui(p):
    n = p.name.lower()
    return p.suffix.lower() in UI_SUFFIX or any(k in n for k in ("copy", "strings", "localizable"))


def collect(paths, root):
    files = []; missing = []
    for a in paths:
        p = pathlib.Path(a)
        if not p.is_absolute():
            p = root / p
        if not p.exists():
            missing.append(a); continue
        if p.is_dir():
            files += sorted(f for f in p.rglob("*") if f.is_file() and f.suffix.lower() in SCAN_SUFFIX)
        else:
            files.append(p)
    return files, missing


def rel(p, root):
    try:
        return str(p.resolve().relative_to(root.resolve()))
    except ValueError:
        return str(p)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="+", help="files or directories to scan")
    ap.add_argument("--strict", action="store_true", help="US spellings in documents are failures too")
    ap.add_argument("--root", default=".", help="base directory for relative paths (default: .)")
    a = ap.parse_args()
    root = pathlib.Path(a.root)
    files, missing = collect(a.paths, root)
    fails = 0; warns = 0
    for m in missing:
        print(f"{m}:0:MISSING: path does not exist")
    for f in files:
        try:
            lines = f.read_text(encoding="utf-8").split("\n")
        except Exception as e:
            print(f"{rel(f, root)}:0:READ: {e}"); fails += 1; continue
        ui = is_ui(f); r = rel(f, root)
        for i, l in enumerate(lines, 1):
            for m in DISCRETE.finditer(l):
                print(f"{r}:{i}:DISCREET: '{m.group(0)}' -> 'Discreet {m.group(1)}' (the product word is Discreet)"); fails += 1
        for i, l in enumerate(mask_lines(lines), 1):
            for w, sug in find_us(l):
                if ui or a.strict:
                    print(f"{r}:{i}:AUSPELL: '{w}' -> '{sug}'"); fails += 1
                else:
                    print(f"{r}:{i}:AUSPELL-WARN: '{w}' -> '{sug}'"); warns += 1
    print(f"au_spelling: {len(files)} files, {fails} failures, {warns} warnings")
    sys.exit(2 if missing else (1 if fails else 0))


if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
