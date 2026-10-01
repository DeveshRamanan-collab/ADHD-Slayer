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
