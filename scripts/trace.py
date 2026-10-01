#!/usr/bin/env python3
"""trace.py [--root DIR] [--allow-missing]

Traceability check (spec: prompts/06_SCRIPT_SPECS.md "trace.py"; prompts/01 Phase 18 and Phase 17).
Parses docs/TRACEABILITY_MATRIX.md, docs/PRODUCT_SPEC.md, docs/TASKS.md, docs/ENGINE_TEST_PLAN.md,
docs/TESTING_STRATEGY.md, docs/FIGMA_AUDIT.md and docs/FIGMA_IMPLEMENTATION_MAP.md under --root.

Definitions follow the shared convention: a heading `### <ID>` (levels 2-4, optionally followed by text)
or a table row whose first cell is `**<ID>**` (a bare `<ID>` first cell is also accepted in the owning
document).  A heading definition's block runs to the next heading of the same or a higher level.
Owning documents: FEAT- PRODUCT_SPEC; TASK- TASKS; TEST- ENGINE_TEST_PLAN and TESTING_STRATEGY;
SCR- FIGMA_AUDIT; UI- FIGMA_IMPLEMENTATION_MAP.  Every fenced region is skipped (fence marker from
scripts/validate_docs.py); inline backticks are kept so a backticked cell is not read as empty.

Rules (file:line:RULE: message)
  ORPHAN-TEST  a TEST- definition maps to no requirement: it is in no matrix row that carries a FEAT-,
               and its own row/block cites no FEAT-/ENG-/DATA-/IOS-/UI-/ARCH-/LEGAL-/INT-/SCR-/COPY- id,
               RL-n or INV-RLn
  FEAT-NOTASK  a FEAT- definition has no TASK-: no TASKS.md row cites it and no matrix row pairs it with a
               TASK-
  TASK-NOTEST  a TASK- row's "verified by" cell (whole row when the table has no such column) has no TEST-
               id and no reasoned N/A ("N/A (<reason of at least three words>)")
  TEST-UNDEF   a TEST- id cited in a TASK "verified by" cell or in the matrix is not defined
  SCR-NOUI     a SCR- definition has no UI- row: no FIGMA_IMPLEMENTATION_MAP UI- row cites the SCR- id or
               one of the node ids (n:n) in the SCR- definition, and no matrix row pairs it with a UI-
  MATRIX-CELL  a matrix data row has an empty cell (whitespace, '-', '—', '–', 'n/a', 'N/A', 'TBC', '?',
               or 'N/A (...)' with a reason under three words); the column header is named
  MISSING      an input document does not exist (exit 2; --allow-missing treats it as empty instead)
Exit 1 on any rule hit; 2 when an input is missing (without --allow-missing); 0 clean.
"""
import argparse, os, pathlib, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import validate_docs as V  # noqa: E402

DOCS = {"matrix": "docs/TRACEABILITY_MATRIX.md", "product": "docs/PRODUCT_SPEC.md", "tasks": "docs/TASKS.md",
        "engine_tests": "docs/ENGINE_TEST_PLAN.md", "testing": "docs/TESTING_STRATEGY.md",
        "audit": "docs/FIGMA_AUDIT.md", "map": "docs/FIGMA_IMPLEMENTATION_MAP.md"}
ID = lambda p: re.compile(r"\b%s-\d{4}\b" % p)
FEAT, TASK, TEST, SCR, UI = ID("FEAT"), ID("TASK"), ID("TEST"), ID("SCR"), ID("UI")
REQ = re.compile(r"\b(?:(?:FEAT|ENG|DATA|IOS|UI|ARCH|LEGAL|INT|SCR|COPY)-\d{4}|RL-\d|INV-RL\d)\b")
NODE = re.compile(r"\b\d{1,6}:\d{1,6}\b")


def split(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def is_sep(line):
    return bool(re.match(r"^\|[\s:\-|]+\|?$", line.strip()))


def empty(c):
    c = re.sub(r"[*`]", "", c).strip()
    m = re.match(r"^N/A\s*\((.*)\)$", c, re.I)
    if m:
        return len(m.group(1).split()) < 3
    return c in V.EMPTY_CELL


class Doc:
    def __init__(self, path, rel):
        self.rel = rel; self.raw = path.read_text(encoding="utf-8").split("\n") if path else []
        self.lines = []; fence = False
        for l in self.raw:  # every fenced region is skipped; backticked text is kept so cells are not emptied
            if re.match(r"^" + V.FENCE, l):
                fence = not fence; self.lines.append(""); continue
            self.lines.append("" if fence else l)
        self.tables = []  # (line_no, header_cells, cells, masked_line)
        header = None
        for i, l in enumerate(self.lines, 1):
            if not l.strip().startswith("|"):
                header = None; continue
            if is_sep(l):
                continue
            nxt = self.lines[i] if i < len(self.lines) else ""
            if header is None and is_sep(nxt):
                header = split(l); continue
            self.tables.append((i, header or [], split(l), l))

    def defs(self, rx):
        """{id: (line, block_text)} for heading and table-first-cell definitions."""
        out = {}
        for i, l in enumerate(self.lines, 1):
            h = re.match(r"^(#{2,4})\s+\**(\S+?)\**(\s|$)", l)
            if h and rx.fullmatch(h.group(2)):
                lvl = len(h.group(1)); block = [l]
                for l2 in self.lines[i:]:
                    m2 = re.match(r"^(#{1,6})\s", l2)
                    if m2 and len(m2.group(1)) <= lvl:
                        break
                    block.append(l2)
                out.setdefault(h.group(2), (i, "\n".join(block)))
        for i, hdr, cells, l in self.tables:
            c0 = re.sub(r"\*", "", cells[0]).strip() if cells else ""
            if rx.fullmatch(c0):
                out.setdefault(c0, (i, l))
        return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".", help="project or fixture root (default: .)")
    ap.add_argument("--allow-missing", action="store_true", help="treat absent documents as empty instead of exit 2")
    a = ap.parse_args()
    root = pathlib.Path(a.root); errs = []; missing = []; d = {}
    for k, r in DOCS.items():
        p = root / r
        if p.exists():
            d[k] = Doc(p, r)
        else:
            missing.append(r); d[k] = Doc(None, r)
    for m in missing:
        print(f"{m}:0:MISSING: document not found")
    if missing and not a.allow_missing:
        print(f"trace: {len(missing)} documents missing"); sys.exit(2)

    mrows = d["matrix"].tables
    for i, hdr, cells, l in mrows:
        for j, c in enumerate(cells):
            if empty(c):
                col = hdr[j] if j < len(hdr) else f"column {j + 1}"
                errs.append((d["matrix"].rel, i, "MATRIX-CELL", f"empty cell in column '{col}'"))
    feats = d["product"].defs(FEAT); tasks = d["tasks"].defs(TASK)
    tests = {}
    for k in ("engine_tests", "testing"):
        for t, (ln, blk) in d[k].defs(TEST).items():
            tests.setdefault(t, (d[k].rel, ln, blk))
    scrs = d["audit"].defs(SCR); uis = d["map"].defs(UI)

    for t, (f, ln, blk) in sorted(tests.items()):
        in_matrix = any(t in set(TEST.findall(l)) and FEAT.search(l) for _, _, _, l in mrows)
        own = REQ.search(blk.replace(t, ""))
        if not in_matrix and not own:
            errs.append((f, ln, "ORPHAN-TEST", f"{t} maps to no requirement (no matrix FEAT- row, no requirement id in its definition)"))
    task_text = [l for _, _, _, l in d["tasks"].tables if TASK.search(l)]
    for fid, (ln, _) in sorted(feats.items()):
        if not any(fid in FEAT.findall(l) for l in task_text) and not any(fid in FEAT.findall(l) and TASK.search(l) for _, _, _, l in mrows):
            errs.append((d["product"].rel, ln, "FEAT-NOTASK", f"{fid} has no TASK-"))
    for i, hdr, cells, l in d["tasks"].tables:
        c0 = re.sub(r"\*", "", cells[0]).strip() if cells else ""
        if not TASK.fullmatch(c0):
            continue
        vj = next((j for j, h in enumerate(hdr) if "verified" in h.lower()), None)
        cell = cells[vj] if vj is not None and vj < len(cells) else l
        ids = TEST.findall(cell)
        if not ids and not re.search(r"N/A\s*\(\s*\S+\s+\S+\s+\S+[^)]*\)", cell, re.I):
            errs.append((d["tasks"].rel, i, "TASK-NOTEST", f"{c0} has no TEST- and no reasoned N/A"))
        for t in ids:
            if t not in tests:
                errs.append((d["tasks"].rel, i, "TEST-UNDEF", f"{c0} cites {t}, which is not defined"))
    for i, _, _, l in mrows:
        for t in TEST.findall(l):
            if t not in tests:
                errs.append((d["matrix"].rel, i, "TEST-UNDEF", f"matrix cites {t}, which is not defined"))
    ui_rows = [blk for _, blk in uis.values()]
    for sid, (ln, blk) in sorted(scrs.items()):
        nodes = set(NODE.findall(blk))
        hit = any(sid in r or (nodes & set(NODE.findall(r))) for r in ui_rows)
        hit = hit or any(sid in SCR.findall(l) and UI.search(l) for _, _, _, l in mrows)
        if not hit:
            errs.append((d["audit"].rel, ln, "SCR-NOUI", f"{sid} has no UI- row" + (f" (node ids {', '.join(sorted(nodes))})" if nodes else "")))

    for f, ln, rule, msg in errs:
        print(f"{f}:{ln}:{rule}: {msg}")
    print(f"trace: {len(feats)} FEAT, {len(tasks)} TASK, {len(tests)} TEST, {len(scrs)} SCR, {len(uis)} UI, "
          f"{len(mrows)} matrix rows; {len(errs)} failures")
    sys.exit(1 if errs else (2 if missing and not a.allow_missing else 0))


if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
