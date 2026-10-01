#!/usr/bin/env python3
"""claims.py <file> [--sample]   Lists verifiable claims (index, line, kind, text). --sample prints only the deterministic sample:
every index ≡ 0 (mod ceil(N/max(10,N/10))) plus every claim whose line has a red-line term or a LEGAL- id."""
import sys,re,math
KINDS=[("node",re.compile(r"\b\d+:\d+\b")),("url",re.compile(r"https?://\S+")),("verified",re.compile(r"verified 20\d\d-\d\d-\d\d")),
 ("version",re.compile(r"\b\d+\.\d+(\.\d+)?\b")),("legal",re.compile(r"\b(Act|Regulation|Determination|Guideline|APP \d|s \d+[A-Z]*)\b")),
 ("verb",re.compile(r"\b(ran|tested|verified|inspected|confirmed|checked|built|passed|measured)\b",re.I))]
RED=re.compile(r"onset|peak|wear-?off|predict|optimal|missed|streak|overdue|LEGAL-\d{4}",re.I)
def main():
    p=sys.argv[1]; sample="--sample" in sys.argv; claims=[]
    for i,l in enumerate(open(p,encoding="utf-8").read().split("\n"),1):
        kinds=[k for k,r in KINDS if r.search(l)]
        if kinds: claims.append((len(claims)+1,i,"+".join(kinds),l.strip()[:160]))
    N=len(claims); step=max(1,math.ceil(N/max(10,N/10))) if N else 1
    for idx,line,kind,text in claims:
        pick=(idx%step==0) or bool(RED.search(text))
        if not sample or pick: print(f"{idx}\t{line}\t{kind}\t{'SAMPLE' if pick else ''}\t{text}")
    print(f"# claims={N} step={step}",file=sys.stderr)
if __name__=="__main__": main()
