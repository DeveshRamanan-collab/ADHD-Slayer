#!/usr/bin/env python3
"""append_entry.py <file> <entry-file | ->
Inserts the text of <entry-file> (or stdin with "-") immediately above the final <!-- END OF FILE --> line of <file>
(the append-only convention of OM-5 for docs/DECISION_LOG.md, docs/BLOCKERS.md and similar). Exit 1 if the marker is missing."""
import sys
def main():
    if len(sys.argv) != 3 or sys.argv[1] in ("-h", "--help"):
        print(__doc__); sys.exit(0 if len(sys.argv) > 1 and sys.argv[1] in ("-h", "--help") else 2)
    path, src = sys.argv[1], sys.argv[2]
    entry = sys.stdin.read() if src == "-" else open(src, encoding="utf-8").read()
    s = open(path, encoding="utf-8").read()
    marker = "<!-- END OF FILE -->"
    i = s.rfind(marker)
    if i < 0:
        print(f"{path}:0:END: missing {marker}"); sys.exit(1)
    s = s[:i].rstrip("\n") + "\n\n" + entry.strip("\n") + "\n\n" + s[i:]
    open(path, "w", encoding="utf-8").write(s)
    print(f"append_entry: {path} +{len(entry.splitlines())} lines")
if __name__ == "__main__":
    main()
