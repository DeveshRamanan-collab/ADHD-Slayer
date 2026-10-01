#!/usr/bin/env python3
"""progress.py [--set KEY=VALUE ...] [--log "line"] [--checkpoint "phase|step|note"]
Orchestrator helper for docs/PROGRESS.md: sets header fields (UPDATED is always set to now), prepends a log line under
"## Log (newest first", and prepends a checkpoint row (keeps the last 30). Uses the system clock (C-15)."""
import sys, re, datetime
P = "docs/PROGRESS.md"
def now(): return datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")
def main():
    a = sys.argv[1:]
    if not a or a[0] in ("-h", "--help"): print(__doc__); sys.exit(0)
    s = open(P, encoding="utf-8").read(); ts = now()
    sets = {"UPDATED": ts}; logs = []; cps = []
    i = 0
    while i < len(a):
        if a[i] == "--set": k, _, v = a[i+1].partition("="); sets[k] = v; i += 2
        elif a[i] == "--log": logs.append(a[i+1]); i += 2
        elif a[i] == "--checkpoint": cps.append(a[i+1]); i += 2
        else: print(f"progress.py: unknown arg {a[i]}"); sys.exit(2)
    for k, v in sets.items():
        s, n = re.subn(rf"(?m)^{re.escape(k)}:.*$", f"{k}: {v}", s, count=1)
        if not n: print(f"progress.py: header key {k} not found"); sys.exit(1)
    for line in logs:
        m = s.find("## Log (newest first"); j = s.find("\n", m) + 1
        s = s[:j] + f"- {ts} {line}\n" + s[j:]
    for c in cps:
        ph, st, note = (c.split("|") + ["", "", ""])[:3]
        m = s.find("## Checkpoints"); j = s.find("|---|", m); j = s.find("\n", j) + 1
        s = s[:j] + f"| {ts} | {ph} | {st} | {note} |\n" + s[j:]
        # keep last 30 rows
        seg_start = j; seg_end = s.find("\n\n", seg_start)
        rows = s[seg_start:seg_end].split("\n")
        if len(rows) > 30: s = s[:seg_start] + "\n".join(rows[:30]) + s[seg_end:]
    open(P, "w", encoding="utf-8").write(s)
    print(f"progress.py: updated {', '.join(sets)}; +{len(logs)} log, +{len(cps)} checkpoint")
if __name__ == "__main__": main()
