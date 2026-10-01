# SCRIPT SPECIFICATIONS AND REFERENCE IMPLEMENTATIONS

The orchestrator writes every script in Phase 0.16. Where a reference implementation is given, copy it verbatim (Python 3 standard library only; no third-party packages). Where only a specification is given, implement to spec, add `--help`, exit non-zero on failure, print `file:line:RULE: message`, and prove each script on a fixture with `[EV:`. All scripts live in `scripts/` and are run from the project root.

Conventions shared by every script: Markdown "definition" of an id = a heading line `### <ID>` (optionally followed by ` …`) or a table row whose first cell is exactly `**<ID>**`; everything else is a reference. Fenced regions opened with ```figma-copy, ```quote or ```output and inline backticks are exempt from phrase and placeholder checks. Table cell "empty" = whitespace only or one of `—`, `-`, `–`, `n/a`, `N/A`, `TBC`, `?`; `N/A (<reason of ≥3 words>)` is not empty. Timestamp = `\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}` followed by `Z`, `[+-]\d{2}:?\d{2}`; a timestamp without seconds or offset fails. Evidence link = `[EV: <path>]` where `<path>` starts with `docs/evidence/` and exists.

---

## `scripts/run_logged.sh` — every cited command runs through this (reference implementation)

```bash
#!/usr/bin/env bash
# Usage: scripts/run_logged.sh [--background] <label> -- <command...>
# Writes docs/evidence/<phase>/<label>-<agent>-<ISO-compact>.log with header/footer; refuses to reuse a path.
set -u
BG=0; [ "${1:-}" = "--background" ] && { BG=1; shift; }
label="$1"; shift; [ "${1:-}" = "--" ] && shift
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
phase="$(grep -m1 '^CURRENT_PHASE:' "$ROOT/docs/PROGRESS.md" 2>/dev/null | sed 's/^CURRENT_PHASE:[[:space:]]*//' | tr -c 'A-Za-z0-9.-' '_' | sed 's/_*$//')"
case "$phase" in MS-*|ms-*) dir="ms${phase#*-}"; dir="ms$(echo "$dir" | grep -oE '^[0-9]+')" ;; *) dir="p$(printf '%02d' "$(echo "${phase:-0}" | grep -oE '^[0-9]+' || echo 0)")" ;; esac
agent="${CLAUDE_AGENT_ID:-orchestrator}"; ts="$(date +%Y%m%dT%H%M%S)"
out="$ROOT/docs/evidence/$dir/${label}-${agent}-${ts}.log"; mkdir -p "$(dirname "$out")"
[ -e "$out" ] && { echo "run_logged: refusing to reuse $out" >&2; exit 97; }
{ echo "# cmd: $*"; echo "# cwd: $PWD"; echo "# agent: $agent"; echo "# start: $(date +%Y-%m-%dT%H:%M:%S%z)"; } > "$out"
run() { "$@" >> "$out" 2>&1; code=$?; { echo "# exit: $code"; echo "# end: $(date +%Y-%m-%dT%H:%M:%S%z)"; } >> "$out"; return $code; }
if [ "$BG" = 1 ]; then nohup bash -c "$(declare -f run); run $(printf '%q ' "$@")" >/dev/null 2>&1 & echo "$out"; exit 0; fi
run "$@"; code=$?; echo "$out"; exit $code
```
Rule: a background run's log is polled with `tail -3 <path>`; a missing `# exit:` after 30 minutes is a `B-nnn TIMEOUT`.

---

## `scripts/fetch_excerpt.py` — saves the evidence for a researched fact (reference implementation)

```python
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
```

---

## `scripts/validate_docs.py` — the deliverable validator (reference implementation)

```python
#!/usr/bin/env python3
"""validate_docs.py [--manifest | <file>...] [--json]
Checks deliverables listed in docs/MANIFEST.md (or the given files). Rules (file:line:RULE):
 END      file ends with <!-- END OF FILE -->                      (F4)
 PHRASE   truncation phrases outside exempt regions                  (F3)
 PLACE    placeholder markers outside exempt regions                 (F5)
 CELL     empty or dash-only table cell                              (F5)
 TIME     timestamp without seconds or offset                        (F18)
 IDFMT    malformed id look-alike                                    (F20)
 IDDUP    id defined more than once                                  (F20)
 IDREF    referenced id never defined (deferred until its owning document is DONE in the manifest) (F20)
 IDOWN    id defined outside its owning document                     (F20)
 EV       verification verb without [EV: path] or path missing       (F2)
 EVLOG    cited command log lacks run_logged header/footer           (F2)
 SRC      FEAT-/ENG-/DATA- row without a Source                      (F7)
 EST      time/effort estimate in TASKS or IMPLEMENTATION_PLAN       (F30)
Exit 1 on any failure. Never inspects docs/design, docs/figma/raw, docs/figma/analysis (validate_analysis.py), docs/evidence, docs/parts, docs/agents, research, logs.
docs/AGENT_RULES.md is checked only for its end marker (it quotes banned phrases, verbs and markers by design; gate.py checks red-line identity)."""
import sys, re, os, json, pathlib
ROOT=pathlib.Path(".").resolve()
EXCL=("docs/design/","docs/figma/raw/","docs/figma/analysis/","docs/evidence/","docs/parts/","docs/agents/","research/","logs/")
PREFIX4=["SCR","FRM","CMP","INT","FEAT","ENG","DATA","ARCH","IOS","UI","LEGAL","COPY","RISK","TEST","TASK"]
PREFIX3=["FIGMA-GAP","FACT","PROP","POC","RESIDUAL","Q","D","B","UA","REL"]
OWNER={"SCR":["docs/FIGMA_AUDIT.md"],"FRM":["docs/FIGMA_AUDIT.md"],"CMP":["docs/FIGMA_AUDIT.md"],"INT":["docs/FIGMA_AUDIT.md"],
 "FEAT":["docs/PRODUCT_SPEC.md"],"ENG":["docs/ENGINE_SPEC.md"],"DATA":["docs/DATA_MODEL.md"],"ARCH":["docs/ARCHITECTURE.md"],
 "IOS":["docs/APPLE_PLATFORM_PLAN.md"],"UI":["docs/FIGMA_IMPLEMENTATION_MAP.md","docs/DESIGN_SYSTEM.md"],"LEGAL":["docs/LEGAL_PRIVACY_SAFETY.md"],
 "COPY":["docs/COPY_REVIEW.md"],"RISK":["docs/FAILURE_MODES.md"],"TEST":["docs/ENGINE_TEST_PLAN.md","docs/TESTING_STRATEGY.md"],
 "TASK":["docs/TASKS.md"],"FIGMA-GAP":["docs/figma/FIGMA_STATE_REPORT.md"],"FACT":["docs/FACT_REGISTER.md"],"PROP":["docs/PROPOSALS.md"],
 "POC":["docs/POC_REGISTER.md"],"RESIDUAL":None,"Q":["docs/OPEN_QUESTIONS.md"],"D":["docs/DECISION_LOG.md"],"B":["docs/BLOCKERS.md"],
 "UA":["docs/USER_ACTIONS.md"],"REL":["docs/RELEASE_CHECKLIST.md"]}
ID_OK=re.compile(r"\b(?:(?:%s)-\d{4}|(?:%s)-\d{3}|MS-\d{2}|G[0-5]|BG-\d{2})\b"%("|".join(PREFIX4),"|".join(PREFIX3)))
ID_LOOKALIKE=re.compile(r"\b(?:%s|%s)[ -]?\d{1,4}\b"%("|".join(PREFIX4),"|".join(PREFIX3)))            # upper case, space or hyphen: SCR 1001, SCR-100
ID_LOOKALIKE_LC=re.compile(r"\b(?:%s)-\d{1,4}\b"%("|".join(p.lower() for p in PREFIX4+PREFIX3 if p!="IOS")))  # lower case needs a hyphen: scr-1001 ("iOS 26" is never flagged)
PHRASES=re.compile(r"\betc\.|\band so on\b|\.\.\.|…|similar to (the )?above|remaining (screens|frames|pages|items)|follows? the same pattern|\[continued\]|\band more\b|for brevity",re.I)
PLACE=re.compile(r"\bTODO\b|\bTBD\b|\bFIXME\b|\bXXX\b|lorem ipsum|<placeholder>")
TIME=re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2})?(?:Z|[+-]\d{2}:?\d{2})?")
TIME_OK=re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-]\d{2}:?\d{2})$")
VERBS=re.compile(r"\b(ran|tested|verified|inspected|confirmed|checked|built|passed|measured|spot-checked|executed)\b",re.I)
EV=re.compile(r"\[EV:\s*(docs/evidence/[^\]\s]+)\s*\]")
EST=re.compile(r"\b\d+(\.\d+)?\s*(h|hr|hrs|hours|d|days|sp|points)\b",re.I)
EMPTY_CELL={"","—","-","–","n/a","N/A","TBC","?"}
DONE=set()   # manifest paths with status DONE (IDREF is deferred until the owning document is DONE)
FENCE="`"*3   # built in code so this script can live inside a Markdown fence
def exempt_mask(lines):
    """Return per-line (stripped_line, in_fence) with exempt fences and backticks removed."""
    out=[]; fence=None
    for l in lines:
        m=re.match(r"^"+FENCE+r"(\S*)",l)
        if m:
            if fence is None: fence=m.group(1) or "code"
            else: fence=None
            out.append(("",True)); continue
        if fence is not None:
            out.append(("",True) if fence in ("figma-copy","quote","output") else (l,False)); continue
        out.append((re.sub(r"`[^`\n]*`","",l),False))
    return out
def check(path, manifest_mode):
    rel=str(path.relative_to(ROOT)) if path.is_absolute() else str(path)
    if any(rel.startswith(e) for e in EXCL): return [],{},{}
    try: text=path.read_text(encoding="utf-8")
    except Exception as e: return [(rel,0,"READ",str(e))],{},{}
    lines=text.split("\n"); errs=[]; defs={}; refs={}
    if "<!-- END OF FILE -->" not in text[-400:] and not rel.endswith(".PARTIAL.md"): errs.append((rel,len(lines),"END","missing <!-- END OF FILE -->"))
    if rel=="docs/AGENT_RULES.md": return errs,{},{}   # verbatim rules text quotes banned phrases, verbs and markers by design
    masked=exempt_mask(lines)
    for i,(l,_) in enumerate(masked,1):
        raw=lines[i-1]
        if not l: continue
        if PHRASES.search(l): errs.append((rel,i,"PHRASE",PHRASES.search(l).group(0)))
        if PLACE.search(l): errs.append((rel,i,"PLACE",PLACE.search(l).group(0)))
        for t in TIME.findall(l):
            if not TIME_OK.match(t): errs.append((rel,i,"TIME",t))
        if l.strip().startswith("|") and not re.match(r"^\|\s*-+",l.strip()) and not re.match(r"^\|\s*[:\-| ]+\|$",l.strip()):
            cells=[c.strip() for c in l.strip().strip("|").split("|")]
            for c in cells:
                if c in EMPTY_CELL: errs.append((rel,i,"CELL",f"empty cell '{c}'")); break
        for m in list(ID_LOOKALIKE.finditer(l))+list(ID_LOOKALIKE_LC.finditer(l)):
            if not ID_OK.fullmatch(m.group(0)): errs.append((rel,i,"IDFMT",m.group(0)))
        hdef=re.match(r"^#{2,4}\s+((?:%s)-\d{4}|(?:%s)-\d{3})\b"%("|".join(PREFIX4),"|".join(PREFIX3)),raw)
        cdef=re.match(r"^\|\s*\*\*((?:%s)-\d{4}|(?:%s)-\d{3})\*\*\s*\|"%("|".join(PREFIX4),"|".join(PREFIX3)),raw)
        ident=(hdef or cdef).group(1) if (hdef or cdef) else None
        for m in ID_OK.finditer(l):
            if m.group(0)==ident: defs.setdefault(ident,[]).append((rel,i))
            else: refs.setdefault(m.group(0),[]).append((rel,i))
        if ident:
            pre=ident.rsplit("-",1)[0]; own=OWNER.get(pre)
            if own and rel not in own: errs.append((rel,i,"IDOWN",f"{ident} defined outside {own}"))
            if pre in ("FEAT","ENG","DATA") and cdef and not re.search(r"\b(FIGMA:\d+:\d+|DOC:[^\s|]+#[^\s|]+|ASSUMPTION-\d{3}|FEAT-\d{4}|INT-\d{4}|ENG-\d{4})\b",raw.replace(ident,"")):
                errs.append((rel,i,"SRC",f"{ident} row has no Source"))
        if VERBS.search(l):
            evs=EV.findall(raw)
            if not evs and "[UNVERIFIED]" not in raw: errs.append((rel,i,"EV","verification verb without [EV: docs/evidence/...]"))
            for p in evs:
                fp=ROOT/p
                if not fp.exists(): errs.append((rel,i,"EV",f"evidence path missing: {p}"))
                elif fp.suffix==".log":
                    head=fp.read_text(errors="replace")
                    if "# cmd:" not in head[:400] or "# exit:" not in head[-400:]: errs.append((rel,i,"EVLOG",f"{p} lacks run_logged header/footer"))
        if rel in ("docs/TASKS.md","docs/IMPLEMENTATION_PLAN.md") and EST.search(l): errs.append((rel,i,"EST",EST.search(l).group(0)))
    return errs,defs,refs
def main():
    args=sys.argv[1:]; as_json="--json" in args; args=[a for a in args if a!="--json"]
    files=[]
    if not args or args==["--manifest"]:
        man=ROOT/"docs/MANIFEST.md"
        if not man.exists(): print("docs/MANIFEST.md:0:MANIFEST: missing"); sys.exit(1)
        for l in man.read_text(encoding="utf-8").split("\n"):
            m=re.match(r"^\|\s*((?:docs/|CLAUDE\.md|scripts/)[^\s|]*)\s*\|",l)
            if m and m.group(1).endswith(".md"):
                if re.search(r"\|\s*NOT STARTED\s*\|",l): continue   # not due yet; MISSING applies only to IN PROGRESS / DONE rows
                files.append(ROOT/m.group(1))
                if re.search(r"\|\s*DONE\s*\|",l): DONE.add(m.group(1))
    else: files=[pathlib.Path(a) for a in args]
    errs=[]; defs={}; refs={}
    for f in files:
        if not f.exists(): errs.append((str(f),0,"MISSING","file listed but absent")); continue
        e,d,r=check(f, True); errs+=e
        for k,v in d.items(): defs.setdefault(k,[]).extend(v)
        for k,v in r.items(): refs.setdefault(k,[]).extend(v)
    for k,v in defs.items():
        if len(v)>1: errs.append((v[1][0],v[1][1],"IDDUP",f"{k} also defined at {v[0][0]}:{v[0][1]}"))
    if len(files)>3 or "--manifest" in sys.argv:   # cross-file reference resolution only in manifest mode
        for k,v in refs.items():
            if k in defs or re.match(r"^(G[0-5]|BG-\d{2}|MS-\d{2}|RESIDUAL-\d{3})$",k): continue
            own=OWNER.get(k.rsplit("-",1)[0])
            if own and not all(o in DONE for o in own): continue   # every owning document must be DONE before references are checked
            errs.append((v[0][0],v[0][1],"IDREF",f"{k} never defined"))
    if as_json: print(json.dumps([{"file":f,"line":l,"rule":r,"msg":m} for f,l,r,m in errs],indent=1))
    else:
        for f,l,r,m in errs: print(f"{f}:{l}:{r}: {m}")
        print(f"validate_docs: {len(files)} files, {len(errs)} failures")
    sys.exit(1 if errs else 0)
if __name__=="__main__": main()
```
Rationale per rule is in the docstring. False-positive controls: exempt fences and backticks; table separator rows skipped; `MS-`, gate and `RESIDUAL-` ids are references without a single owning definition; cross-file reference resolution runs only in manifest mode.

---

## `scripts/claims.py` — enumerates verifiable claims for the deterministic sampling rule (reference implementation)

```python
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
```

---

## `scripts/secret_scan.sh` (reference implementation; pre-commit hook)

```bash
#!/usr/bin/env bash
# Scans staged files (or all tracked files with --all) for secrets. Exit 1 on a hit.
set -u
if [ "${1:-}" = "--all" ]; then files="$(git ls-files)"; else files="$(git diff --cached --name-only --diff-filter=ACM)"; fi
pat='ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{20,}|figd_[A-Za-z0-9_-]{20,}|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z_-]{35}'
hit=0
for f in $files; do
  [ -f "$f" ] || continue
  case "$f" in *.p12|*.mobileprovision|*.cer|.env|.env.*) echo "secret_scan: forbidden file type staged: $f"; hit=1; continue;; esac
  if grep -nE "$pat" "$f" >/dev/null 2>&1; then echo "secret_scan: possible secret in $f:"; grep -nE "$pat" "$f" | sed -E 's/([A-Za-z0-9_-]{8})[A-Za-z0-9_-]+/\1…/g' | head -5; hit=1; fi
done
exit $hit
```
Install: `printf '#!/usr/bin/env bash\nbash scripts/secret_scan.sh\n' > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`.

---

## `scripts/check_scope.sh` (reference implementation)

```bash
#!/usr/bin/env bash
# Planning phase: no Swift/Xcode artefacts outside /poc. Exit 1 on violation.
bad="$(find . -type f \( -name '*.swift' -o -name 'Package.swift' \) -not -path './poc/*' -not -path './.git/*' -not -path './.build/*' 2>/dev/null; find . -type d \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) -not -path './poc/*' -not -path './.git/*' 2>/dev/null)"
[ -z "$bad" ] && { echo "check_scope: OK"; exit 0; }
echo "check_scope: production code artefacts outside /poc:"; echo "$bad"; exit 1
```

---

## Specifications for the remaining scripts (implement to spec; each with `--help`, `file:line:RULE` output, non-zero exit on failure, and a fixture run `[EV:`)

**`figma_fingerprint.py <fileKey> [--page <slug>]`** — reads `docs/figma/raw/<fileKey>/<page-slug>/nodes.json` (all pages, or one); builds the sorted list of `(id, name, type, parentId, width, height)` tuples; drops any key whose name contains `url`, `time`, `date`, `thumbnail`, `version`, `expires`; prints SHA-256 of the canonical JSON (`sort_keys=True`, no spaces) per page and for the root (the root fingerprint = SHA-256 over the page fingerprints joined in page order). Writes/updates the `fingerprint` field inside each `nodes.json` and prints a table for `docs/FIGMA_VERSION_LOCK.md`. The orchestrator writes `nodes.json` from the cached `get_metadata` response: parse the response (JSON if the tool returns JSON; otherwise the XML/text node list with `id`, `name`, `type` attributes) into `{page, pageId, nodes:[{id,name,type,parentId,depth,width,height}]}`; if the response format is unrecognised, write `nodes.json` by hand from the response once, log `D-nnn`, and never guess a node that is not in the response.

**`figma_reconcile.py <fileKey> [--candidates <page-slug>] [--strict]`** — from every `nodes.json`: top-level frames (depth 1; type FRAME/COMPONENT/COMPONENT_SET/INSTANCE, parent a CANVAS or SECTION), component sets, components, and interactive-element candidates (prototype reaction present if the index carries it; or INSTANCE/main-component/name matching the Phase 3 regex). From `docs/FIGMA_AUDIT.md` (or `docs/figma/analysis/*.md` when the audit is not yet assembled): node ids in `SCR-/FRM-/CMP-` rows, `INT-` rows and `NON-INTERACTIVE` lines. Prints per page: candidates found vs rows present; ids missing on each side; Platform-column violations (Watch page rows not `Watch`; Glanceables rows not one of the four glanceable platforms); `--candidates` prints the candidate list for one page in the 04-T11 block order; `--strict` exits 1 on any missing id or violation. Exit 2 with a message if a page folder has raw text but no `nodes.json`.

**`figma_read_plan.py <fileKey>`** — from the `nodes.json` set, `docs/figma/TOOL_COVERAGE.md` and the ledger: writes `docs/figma/read-plan.md` with one line per planned read (tier T1–T12, tool, node id, page, frame name, Kind, variant axis, base-variant flag, planned epoch, status planned/done/failed/skipped-variant), the per-tier and per-epoch totals and the cap at the top; marks a line `done` when the ledger has an `ok` row for that node and tool; frames with > 400 descendants are expanded to their direct children. Re-run after every batch.

**`extract_text.py <fileKey>`** — walks every cached `get_design_context` response; extracts TEXT nodes (id, page, frame id, frame name, text, style token, `is_placeholder_guess` = text matches `Loading|Lorem|Placeholder|\.\.\.|…` or a mode-sample pattern) into `docs/figma/text-layers.csv`; lists frames whose cache is metadata-only in `docs/figma/text-layers.NOT-EXTRACTED.md` with the reason (`metadata-only-variant`, `[NOT YET READ]`, `TRUNCATED`).

**`copy_scan.py [--input docs/figma/text-layers.csv | --strings <dir>] [--replacements docs/COPY_REVIEW.md] [--discreet-frames <list>]`** — scans every row against the RL-2 pharmacology regex, the "Don't say" column of `prompts/figma_design_prompt.md` (parsed from the table), the Phase 11.6 category patterns C1–C20 (configurable in a `scripts/copy_rules.json` the orchestrator writes from Phase 11.6), the drug-name list (`docs/figma/drug-names.md`) for Discreet-variant frames and all glanceable/notification/intent surfaces, and the shame/streak list; writes `docs/figma/copy-scan.md` (rows scanned, frames not extracted, hits with node id and category); `--replacements` re-scans the proposed replacement column of `docs/COPY_REVIEW.md` and additionally fails on exclamation marks, praise words (`great|awesome|amazing|well done|congrat`), clinical register (`adherence|compliance|non-compliant|regimen|dosage optimisation|symptom`), US spellings, and length > original + 20%; exit 1 on any hit in a UI-facing set.

**`au_spelling.py <paths...> [--strict]`** — scans prose outside code identifiers, backticks and fenced code for the US-spelling list (`color|behavior|organize|organization|center|license (as a noun)|favorite|gray|analyze|customize|optimize|catalog|canceled|program (for a schedule)|jewelry|liter|meter (unit)|mom|math`); warnings in documents, failures (`--strict`) in UI string files; always fails on "Discrete mode" (the word is "Discreet").

**`check_facts.py`** — reads `docs/FACT_REGISTER.md` (`FACT-nnn | key | canonical value | owning document | synonyms`); for each key greps every manifest deliverable for the key and its synonyms and reports any line that states a different value (numbers, versions, names); exit 1 on mismatch; the orchestrator resolves by editing the non-owning document or superseding the fact with a `D-nnn`.

**`check_names.py`** — reads every `DATA-`/`ENG-`/`ARCH-` definition's name and compares (case-insensitive, exact simple-name match) against `docs/RESERVED_NAMES.md`; exit 1 on collision with the suggested domain-qualified alternative.

**`check_tasks.py`** — parses `docs/TASKS.md`: every `TASK-` row has all Phase 17 columns non-empty; `depends on` references resolve; topological sort succeeds (cycle → list it); no `EST` pattern; every task's `milestone` exists in `docs/IMPLEMENTATION_PLAN.md`.

**`trace.py`** — parses `docs/TRACEABILITY_MATRIX.md`, `docs/PRODUCT_SPEC.md`, `docs/TASKS.md`, `docs/ENGINE_TEST_PLAN.md`, `docs/TESTING_STRATEGY.md`, `docs/FIGMA_AUDIT.md`, `docs/FIGMA_IMPLEMENTATION_MAP.md`: reports orphan `TEST-` (no requirement), `FEAT-` without `TASK-`, `TASK-` without `TEST-` or reasoned `N/A`, `SCR-` without `UI-`, matrix rows with empty cells; exit 1 on any.

**`design_doc_xref.py`** — extracts token, component and state names from `docs/design/handoff.md` and `docs/design/DESIGN_SPEC.md` (headings, table first cells, backticked identifiers) and reports, for each, whether it was found (exact or case-insensitive) in `nodes.json` names, the variables cache or `text-layers.csv`; writes the table to stdout for inclusion in `docs/RECONCILIATION.md` and `docs/DESIGN_SYSTEM.md`; the count of unfound items is reported.

**`validate_analysis.py <page-slug>`** — for `docs/figma/analysis/<page-slug>.md`: section 1 row count equals the `nodes.json` depth-1 count; every candidate from `figma_reconcile.py --candidates` has an `INT-` block or a `NON-INTERACTIVE` line; every `### SCR-/FRM-/CMP-` block with design context cached has sub-headings A–E each with ≥1 non-empty row; every text layer of the page's extracted frames appears in a red-line scan row; section 3 counts are numeric and consistent; ids within the allocated range from `docs/figma/id-ranges.md`; the file ends with `<!-- END OF FILE -->` and has no PHRASE/PLACE hits (reuse validate_docs' masks).

**`assemble_docs.py <DOC> [--order manifest]`** — concatenates `docs/parts/<DOC>/<nn>-*.md` in numeric order (or the page order from `nodes.json` for `FIGMA_AUDIT`), inserts a generated summary table where the part named `00-summary.md` requests it (`{{SUMMARY}}`), appends `<!-- END OF FILE -->`, writes `docs/<DOC>.md`, and refuses to run if any part lacks its own end marker or is `.PARTIAL.md`.

**`gate.py G<n>`** — runs the mechanical items of the OM-4 row for that gate (calls the scripts above, checks PROGRESS counters, ledger/cache reconciliation, the `[NOT YET READ]` and `metadata-only-variant` rules, hard-fail classes) and prints a PASS/FAIL table in the 04-T3 format for the reviewer to complete; exit 1 on any FAIL; `--loop <n>` records the loop number. Includes **REDLINE**: extract the RL-1–RL-9 table (from the line starting `| RL-1` to the line starting `| RL-9`) from `docs/PRODUCT_SPEC.md`, `docs/ENGINE_SPEC.md`, `docs/COPY_REVIEW.md`, `docs/LEGAL_PRIVACY_SAFETY.md`, `docs/CLAUDE_CODE_INSTRUCTIONS.md`, `CLAUDE.md` and `docs/AGENT_RULES.md` (each document present at that gate); SHA-256 each; any mismatch → `file:line:REDLINE` and exit 1; run at G3, G4 and G5.

**`run_planning.sh`** — the optional runner specified in `prompts/05_SETTINGS_AND_HOOKS.md`; proven only with `bash -n` and `--help` (it is never launched by the orchestrator, and guard_bash blocks it).

<!-- END OF FILE -->
