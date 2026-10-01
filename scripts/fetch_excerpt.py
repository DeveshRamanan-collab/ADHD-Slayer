#!/usr/bin/env python3
"""Usage: fetch_excerpt.py <URL> <ID> "<must-contain phrase>" [--text-file path]
Fetches URL (or reads --text-file when WebFetch already produced the text), saves docs/evidence/sources/<ID>.md with
URL, retrieval time, HTTP status, SHA-256 of the text, and the <=80-word excerpt around the phrase. Exit 1 if the phrase is absent
(the claim is then [UNVERIFIED]). Never prints or stores secrets; no auth headers."""
import sys, re, hashlib, datetime, urllib.request, html, pathlib
def main():
    a=sys.argv[1:]
    if len(a)<3: print(__doc__); sys.exit(2)
    url, ident, phrase = a[0], a[1], a[2]; text=None; status="n/a"
    if "--text-file" in a: text=open(a[a.index("--text-file")+1],encoding="utf-8",errors="replace").read(); status="from-text-file"
    else:
        req=urllib.request.Request(url, headers={"User-Agent":"planner-planning-run/1.0"})
        try:
            with urllib.request.urlopen(req, timeout=60) as r: raw=r.read(); status=str(r.status)
            text=re.sub(r"<[^>]+>"," ",html.unescape(raw.decode("utf-8",errors="replace")))
        except Exception as e: text=""; status=f"error: {e.__class__.__name__}"
    text=re.sub(r"\s+"," ",text or "")
    i=text.lower().find(phrase.lower()); ok=i>=0
    words=text.split(" ")
    if ok:
        start=len(text[:i].split(" ")); ex=" ".join(words[max(0,start-30):start+50])
    else: ex="PHRASE NOT FOUND"
    p=pathlib.Path("docs/evidence/sources")/f"{ident}.md"; p.parent.mkdir(parents=True,exist_ok=True)
    now=datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")
    p.write_text(f"# {ident}\nurl: {url}\nretrieved: {now}\nhttp: {status}\nsha256: {hashlib.sha256(text.encode()).hexdigest()}\nphrase: {phrase}\nfound: {ok}\n\n## Excerpt\n{ex}\n",encoding="utf-8")
    print(f"{p} found={ok}"); sys.exit(0 if ok else 1)
if __name__=="__main__": main()
