#!/usr/bin/env python3
"""check_tasks.py [--root DIR] [--tasks PATH] [--plan PATH]

Task-database check (spec: prompts/06_SCRIPT_SPECS.md "check_tasks.py"; columns: prompts/01 Phase 17;
gate G4 item 3).  Parses docs/TASKS.md; every table row whose first cell is a TASK-nnnn id (bold or not)
is a task.  Columns are mapped from the table header by name (case-insensitive):

  TASK id | type | milestone | description | depends on | implements | Figma reference |
  expected implementation | verified by | completion criterion | size | suggested agent/tool

Rules (file:line:RULE: message)
  HEADER  a TASK table lacks one of the twelve Phase 17 columns
  CELL    a required cell is empty ('', '—', '-', '–', 'n/a', 'N/A', 'TBC', '?'; 'N/A (<reason>)' is fine)
  DUP     a TASK id appears as a row more than once
  TYPE    type not in ARCH/ENG/DATA/IOS/UI/INT/TEST/LEGAL/DOC
  SIZE    size not S, M or L
  MS      milestone cell is not MS-nn, or that MS-nn is not defined in docs/IMPLEMENTATION_PLAN.md
          (a heading, a table row first cell, or a list item starting "**MS-nn")
  DEP     a 'depends on' TASK id does not resolve to a task row
  CYCLE   the dependency graph has a cycle (each cycle listed)
  CRIT    completion criterion is not quoted (Phase 17: "quoted, testable")
  EST     a time/effort estimate anywhere in TASKS.md outside backticks and exempt fences (F30)
Exit 1 on any failure; 2 when docs/TASKS.md or docs/IMPLEMENTATION_PLAN.md does not exist yet; 0 clean.
"""
import argparse, os, pathlib, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import validate_docs as V  # noqa: E402

COLS = [("id", r"^(task|id)\b"), ("type", r"^type\b"), ("milestone", r"milestone"), ("description", r"description"),
        ("depends", r"depend"), ("implements", r"^implements"), ("figma", r"figma"), ("expected", r"expected"),
        ("verified", r"verified"), ("completion", r"completion"), ("size", r"^size"), ("agent", r"agent|tool")]
TYPES = {"ARCH", "ENG", "DATA", "IOS", "UI", "INT", "TEST", "LEGAL", "DOC"}
TASK_RE = re.compile(r"\bTASK-\d{4}\b")


def split(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def is_sep(line):
    return bool(re.match(r"^\|[\s:\-|]+\|?$", line.strip()))


def map_header(cs):
    m = {}
    for j, h in enumerate(cs):
        hl = re.sub(r"[*`]", "", h).strip().lower()
        for key, pat in COLS:
            if key not in m and re.search(pat, hl):
                m[key] = j; break
    return m


def empty(c):
    c = c.strip()
    if c.upper().startswith("N/A (") and c.endswith(")"):
        return False
    return c in V.EMPTY_CELL


def milestones(plan_text):
    ms = set()
    for l in plan_text.split("\n"):
        for pat in (r"^#{1,6}\s.*?\b(MS-\d{2})\b", r"^\|\s*\**(MS-\d{2})\**\s*\|", r"^\s*[-*]\s+\*\*(MS-\d{2})\b"):
            m = re.match(pat, l)
            if m:
                ms.add(m.group(1))
    return ms


def find_cycles(graph):
    cycles = []; color = {}; stack = []
    def dfs(u):
        color[u] = 1; stack.append(u)
        for v in sorted(graph.get(u, ())):
            if v not in graph:
                continue
            if color.get(v, 0) == 0:
                dfs(v)
            elif color.get(v) == 1:
                cyc = stack[stack.index(v):] + [v]
                if sorted(cyc[:-1]) not in [sorted(c[:-1]) for c in cycles]:
                    cycles.append(cyc)
        stack.pop(); color[u] = 2
    sys.setrecursionlimit(max(10000, len(graph) * 4))
    for n in sorted(graph):
        if color.get(n, 0) == 0:
            dfs(n)
    return cycles


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".")
    ap.add_argument("--tasks", default="docs/TASKS.md")
    ap.add_argument("--plan", default="docs/IMPLEMENTATION_PLAN.md")
    a = ap.parse_args()
    root = pathlib.Path(a.root).resolve()
    missing = [p for p in (a.tasks, a.plan) if not (root / p).exists()]
    if missing:
        for p in missing:
            print("%s:0:MISSING: input document does not exist yet" % p)
        print("check_tasks: cannot run until %s exist" % " and ".join(missing)); sys.exit(2)
    rel = a.tasks
    lines = (root / a.tasks).read_text(encoding="utf-8").split("\n")
    masked = V.exempt_mask(lines)
    ms_defined = milestones((root / a.plan).read_text(encoding="utf-8"))
    errs = []; tasks = {}; header = None; hdr_line = 0; header_reported = set()
    for i, raw in enumerate(lines, 1):
        ml, in_fence = masked[i - 1]
        if ml and V.EST.search(ml) and not in_fence:
            errs.append((i, "EST", "estimate '%s' (F30; write platform durations in backticks)" % V.EST.search(ml).group(0)))
        s = raw.strip()
        if not s.startswith("|") or in_fence:
            header = None; continue
        if is_sep(s):
            continue
        cs = split(s)
        first = re.sub(r"[*`]", "", cs[0]).strip()
        if not re.fullmatch(r"TASK-\d{4}", first):
            if header is None:
                header = map_header(cs); hdr_line = i
            continue
        if header is None:
            header = {}; hdr_line = i
        if hdr_line not in header_reported:
            header_reported.add(hdr_line)
            for key, _ in COLS:
                if key not in header:
                    errs.append((hdr_line, "HEADER", "TASK table lacks the '%s' column (Phase 17)" % key))
        tid = first
        if tid in tasks:
            errs.append((i, "DUP", "%s also a row at line %d" % (tid, tasks[tid]["line"]))); continue
        row = {"line": i}
        for key, _ in COLS:
            j = header.get(key)
            row[key] = cs[j] if j is not None and j < len(cs) else ""
            if j is not None and empty(row[key]):
                errs.append((i, "CELL", "%s '%s' cell is empty" % (tid, key)))
        tasks[tid] = row
        t = re.sub(r"[*`]", "", row["type"]).strip()
        if "type" in header and t and t not in TYPES:
            errs.append((i, "TYPE", "%s type '%s' not in %s" % (tid, t, "/".join(sorted(TYPES)))))
        sz = re.sub(r"[*`]", "", row["size"]).strip()
        if "size" in header and sz and sz not in ("S", "M", "L"):
            errs.append((i, "SIZE", "%s size '%s' not S/M/L" % (tid, sz)))
        if "milestone" in header and row["milestone"]:
            mm = re.search(r"\bMS-\d{2}\b", row["milestone"])
            if not mm:
                errs.append((i, "MS", "%s milestone '%s' is not MS-nn" % (tid, row["milestone"])))
            elif mm.group(0) not in ms_defined:
                errs.append((i, "MS", "%s milestone %s not defined in %s" % (tid, mm.group(0), a.plan)))
        if "completion" in header and row["completion"] and not re.search(r"[\"“”]", row["completion"]):
            errs.append((i, "CRIT", "%s completion criterion is not quoted" % tid))
    graph = {}
    for tid, row in tasks.items():
        deps = set(TASK_RE.findall(row.get("depends", "")))
        graph[tid] = deps
        for d in sorted(deps):
            if d not in tasks:
                errs.append((row["line"], "DEP", "%s depends on %s, which is not a task row" % (tid, d)))
    for cyc in find_cycles(graph):
        errs.append((tasks[cyc[0]]["line"], "CYCLE", "dependency cycle: " + " -> ".join(cyc)))
    if not tasks:
        errs.append((0, "EMPTY", "no TASK-nnnn rows found"))
    errs.sort(key=lambda e: e[0])
    for l, r, m in errs:
        print("%s:%d:%s: %s" % (rel, l, r, m))
    print("check_tasks: %d tasks, %d milestones defined, %d failures" % (len(tasks), len(ms_defined), len(errs)))
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
