#!/usr/bin/env python3
"""copy_scan.py [--root DIR] [--input CSV | --strings DIR] [--replacements COPY_REVIEW.md]
               [--discreet-frames LIST] [--wording PATH] [--drug-names PATH] [--rules PATH] [--output PATH]

Copy red-line scan (spec: prompts/06_SCRIPT_SPECS.md "copy_scan.py"; red lines RL-2, RL-3, RL-4, RL-5;
prompts/01 Phase 11.6 categories C1-C20).  Every row/string is scanned against:
  RL2       the RL-2 pharmacology list: onset, peak, wear-off / wears off / wearing off, kicks in, half-life,
            crash, rebound, effective, levels, predicts, optimal
  DONTSAY   every quoted phrase in the "Don't say" column of the wording table in
            prompts/figma_design_prompt.md (section "Wording rules"), case-insensitive, apostrophes normalised
  C1..C20   Phase 11.6 category patterns from scripts/copy_rules.json (written by the orchestrator in
            Phase 11.6).  Format: {"categories": {"C3": {"rule": "RL-1", "patterns": ["regex", ...],
            "glanceable_only": false}}}.  When the file is absent a NOTE line is printed and the scan runs
            with RL2, DONTSAY, DRUG and SHAME only.
  DRUG      the drug-name list (docs/figma/drug-names.md: bullet items or table first cells; a built-in
            list of ADHD medicines and classes is used, with a NOTE, when the file is absent) - applied to
            Discreet-variant frames (frame name contains "Discreet", or listed in --discreet-frames) and to
            every glanceable/notification/intent surface (page, frame, file or key naming Lock Screen,
            notification, widget, Live Activity, Dynamic Island, Control Center/Centre, Siri, intent,
            complication, calendar/EventKit, StandBy, Smart Stack, glanceable)
  SHAME     the RL-4 shame/streak list: missed, overdue, streak(s), skipped, you forgot, don't break,
            falling behind
With --replacements, the proposed replacement column of docs/COPY_REVIEW.md (rows whose first cell is a
COPY-nnnn id; columns located by the header names "original" and "replacement") is re-scanned with all of
the above and additionally fails on:
  EXCLAIM   an exclamation mark
  PRAISE    great | awesome | amazing | well done | congrat
  CLINICAL  adherence | compliance | non-compliant | regimen | dosage optimisation | symptom
  AUSPELL   a US spelling (scripts/au_spelling.py list)
  LENGTH    replacement longer than the original + 20 %
Inputs: --input (default docs/figma/text-layers.csv; header columns id/node id, page, frame id, frame name,
text) or --strings DIR (.strings "key" = "value"; .json/.xcstrings "key": "value"; .txt/.md one string per
line outside fenced code and backticks).  Every input set is UI-facing.
Writes --output (default docs/figma/copy-scan.md): rows scanned, frames, frames not extracted (from
docs/figma/text-layers.NOT-EXTRACTED.md when present), hits with node id and category.
Prints file:line:RULE: message per hit.  Exit 1 on any hit; 2 when an input file is missing; 0 clean.
All relative paths resolve against --root (default: .); --wording also falls back to the project root.
"""
import argparse, csv, json, os, pathlib, re, sys
HERE = pathlib.Path(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, str(HERE))
import au_spelling as AU  # noqa: E402

RL2 = re.compile(r"\b(onset|peak(s|ed|ing)?|wear[\s-]?off|wears\s+off|wearing\s+off|kicks?\s+in|half[\s-]?life|crash(es|ed|ing)?|rebound(s|ing)?|effective|levels|predicts?|optimal)\b", re.I)
SHAME = re.compile(r"\b(missed|overdue|streaks?|skipped|you forgot|don't break|falling behind)\b", re.I)
EXCLAIM = re.compile(r"!")
PRAISE = re.compile(r"\b(great|awesome|amazing|well done|congrat\w*)\b", re.I)
CLINICAL = re.compile(r"\b(adherence|compliance|non-compliant|regimen|dosage optimisation|symptoms?)\b", re.I)
GLANCE = re.compile(r"lock\s*screen|notification|widget|live\s*activit|dynamic\s*island|control\s*(cent(er|re)|widget)|siri|intent|complication|calendar|eventkit|standby|smart\s*stack|glanceable", re.I)
BUILTIN_DRUGS = ["methylphenidate", "Ritalin", "Concerta", "Rubifen", "Artige", "dexamfetamine", "dexamphetamine",
                 "lisdexamfetamine", "Vyvanse", "amphetamine", "Adderall", "atomoxetine", "Strattera", "guanfacine",
                 "Intuniv", "clonidine", "modafinil", "stimulant", "Schedule 8"]
FENCE = "`" * 3


def norm(s):
    return s.replace("\u2019", "'").replace("\u2018", "'").replace("\u201c", '"').replace("\u201d", '"')


def resolve(root, p, fallback=False):
    q = pathlib.Path(p)
    if q.is_absolute():
        return q
    if (root / q).exists() or not fallback:
        return root / q
    return HERE.parent / q


def rel(p, root):
    for base, tag in ((root, ""), (HERE.parent, " (project root)")):
        try:
            return str(p.resolve().relative_to(base.resolve())) + tag
        except ValueError:
            pass
    return str(p)


def split(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def is_sep(line):
    return bool(re.match(r"^\|[\s:\-|]+\|?$", line.strip()))


def parse_dontsay(path):
    """Quoted phrases from the Don't-say column of the table under the 'Wording rules' heading."""
    lines = path.read_text(encoding="utf-8").split("\n"); out = []; inside = False; col = None
    for l in lines:
        if re.match(r"^#{1,6}\s.*wording rules", l, re.I):
            inside = True; col = None; continue
        if inside and re.match(r"^#{1,6}\s", l):
            break
        if inside and l.strip().startswith("|"):
            if is_sep(l):
                continue
            cs = split(norm(l))
            if col is None:
                col = next((j for j, c in enumerate(cs) if re.search(r"don't say", c, re.I)), 1); continue
            if col < len(cs):
                out += [p.strip() for p in re.findall(r'"([^"]+)"', cs[col]) if p.strip()]
    return out


def parse_drugs(path):
    names = []
    for l in path.read_text(encoding="utf-8").split("\n"):
        m = re.match(r"^\s*[-*]\s+(.+)$", l)
        if m:
            names.append(re.split(r"\s+[\u2014(-]\s*|\s*\(", m.group(1))[0]); continue
        if l.strip().startswith("|") and not is_sep(l):
            c = split(l)[0]
            if c and not re.match(r"^(name|drug|medicine|brand|generic)s?$", c, re.I):
                names.append(c)
    return [re.sub(r"[*`]", "", n).strip() for n in names if re.sub(r"[*`]", "", n).strip()]


class Scanner:
    def __init__(self, dontsay, rules, drugs):
        self.dontsay = [(p, re.compile(r"(?<!\w)" + re.escape(norm(p)) + r"(?!\w)", re.I)) for p in dontsay]
        self.rules = rules
        self.drug = re.compile(r"\b(" + "|".join(re.escape(d) for d in sorted(drugs, key=len, reverse=True)) + r")\b", re.I) if drugs else None

    def scan(self, text, glance, replacement=False, original=None):
        t = norm(text); hits = []
        for m in RL2.finditer(t):
            hits.append(("RL2", "C4", f"pharmacology term '{m.group(0)}' (RL-2)"))
        for p, rx in self.dontsay:
            if rx.search(t):
                hits.append(("DONTSAY", "RL-5", f"Don't-say phrase '{p}'"))
        for cid, spec in self.rules.items():
            if spec.get("glanceable_only") and not glance:
                continue
            for pat in spec.get("patterns", []):
                m = re.search(pat, t, re.I)
                if m:
                    hits.append((cid, cid, f"'{m.group(0)}' ({spec.get('rule', cid)})")); break
        if glance and self.drug:
            for m in self.drug.finditer(t):
                hits.append(("DRUG", "C8", f"drug name '{m.group(0)}' on a Discreet/glanceable surface (RL-3)"))
        for m in SHAME.finditer(t):
            hits.append(("SHAME", "C6/C12", f"shame/streak word '{m.group(0)}' (RL-4)"))
        if replacement:
            if EXCLAIM.search(t):
                hits.append(("EXCLAIM", "F29", "exclamation mark in a replacement"))
            for m in PRAISE.finditer(t):
                hits.append(("PRAISE", "F29", f"praise word '{m.group(0)}'"))
            for m in CLINICAL.finditer(t):
                hits.append(("CLINICAL", "C11", f"clinical register '{m.group(0)}'"))
            for w, sug in AU.find_us(AU.mask_lines([t])[0]):
                hits.append(("AUSPELL", "F29", f"US spelling '{w}' -> '{sug}'"))
            if original is not None and len(t) > len(norm(original)) * 1.2:
                hits.append(("LENGTH", "F29", f"replacement {len(t)} chars > original {len(norm(original))} + 20%"))
        return hits


def read_csv(path, discreet):
    rows = []
    with path.open(encoding="utf-8", newline="") as f:
        rd = csv.reader(f); header = None
        for rec in rd:
            if header is None:
                header = [re.sub(r"[\s_]+", " ", h.strip().lower()) for h in rec]; continue
            d = dict(zip(header, rec))
            node = d.get("id") or d.get("node id") or ""
            frame = d.get("frame name", ""); fid = d.get("frame id", ""); page = d.get("page", "")
            glance = bool(GLANCE.search(" ".join((page, frame)))) or "discreet" in frame.lower() or fid in discreet or frame in discreet
            rows.append({"line": rd.line_num, "node": node, "frame": fid or frame, "frame_name": frame, "text": d.get("text", ""), "glance": glance})
    return rows


def read_strings(d, root):
    rows = []
    for f in sorted(p for p in d.rglob("*") if p.is_file()):
        suf = f.suffix.lower(); r = rel(f, root)
        try:
            lines = f.read_text(encoding="utf-8").split("\n")
        except Exception:
            continue
        fence = False
        for i, l in enumerate(lines, 1):
            key = r; text = None
            if suf in (".strings", ".stringsdict"):
                m = re.match(r'^\s*"((?:[^"\\]|\\.)*)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;', l)
                if m:
                    key, text = m.group(1), m.group(2)
            elif suf in (".json", ".xcstrings"):
                m = re.match(r'^\s*"((?:[^"\\]|\\.)*)"\s*:\s*"((?:[^"\\]|\\.)*)"\s*,?\s*$', l)
                if m:
                    key, text = m.group(1), m.group(2)
            elif suf in (".txt", ".md"):
                if re.match(r"^\s*" + FENCE, l):
                    fence = not fence; continue
                if not fence and not l.startswith("#"):
                    text = re.sub(r"`[^`\n]*`", " ", l).strip() or None
            if text:
                rows.append({"file": r, "line": i, "node": f"{r}#{key}", "frame": r, "frame_name": key, "text": text,
                             "glance": bool(GLANCE.search(r + " " + key)) or "discreet" in (r + key).lower()})
    return rows


def read_replacements(path):
    lines = path.read_text(encoding="utf-8").split("\n"); rows = []; col = None; fence = False
    for i, l in enumerate(lines, 1):
        if re.match(r"^\s*" + FENCE, l):
            fence = not fence; continue
        if fence or not l.strip().startswith("|") or is_sep(l):
            continue
        cs = split(l)
        low = [re.sub(r"[*`]", "", c).lower() for c in cs]
        if any("replacement" in c for c in low):
            col = {"orig": next((j for j, c in enumerate(low) if "original" in c), 2),
                   "repl": next(j for j, c in enumerate(low) if "replacement" in c),
                   "node": next((j for j, c in enumerate(low) if "node" in c or "surface" in c), 1)}
            continue
        if not re.match(r"^\**COPY-\d{4}\**$", cs[0]):
            continue
        c = col or {"orig": 2, "repl": 6, "node": 1}
        if c["repl"] >= len(cs):
            continue
        strip = lambda s: re.sub(r"^[\"\u201c`]+|[\"\u201d`]+$", "", s.strip())
        repl = strip(cs[c["repl"]]); orig = strip(cs[c["orig"]]) if c["orig"] < len(cs) else ""
        if repl.lower() in ("", "none", "n/a", "-", "\u2014") or repl.upper().startswith("N/A ("):
            continue
        node = cs[c["node"]] if c["node"] < len(cs) else ""
        rows.append({"line": i, "node": re.sub(r"[*]", "", cs[0]) + " " + node, "frame": node, "frame_name": node,
                     "text": repl, "orig": orig, "glance": bool(GLANCE.search(node)) or "discreet" in node.lower()})
    return rows


def esc(s):
    return s.replace("|", "\\|").replace("`", "'")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", default=".", help="project or fixture root (default: .)")
    ap.add_argument("--input", help="text-layers CSV (default docs/figma/text-layers.csv)")
    ap.add_argument("--strings", help="directory of UI string files")
    ap.add_argument("--replacements", help="COPY_REVIEW.md whose replacement column is re-scanned")
    ap.add_argument("--discreet-frames", default="", help="comma-separated frame ids or names treated as Discreet variants")
    ap.add_argument("--wording", default="prompts/figma_design_prompt.md", help="file holding the Say / Don't say table")
    ap.add_argument("--drug-names", default="docs/figma/drug-names.md", help="drug-name list")
    ap.add_argument("--rules", default="scripts/copy_rules.json", help="Phase 11.6 C1-C20 patterns")
    ap.add_argument("--output", default="docs/figma/copy-scan.md", help="report path")
    a = ap.parse_args()
    root = pathlib.Path(a.root); discreet = {x.strip() for x in a.discreet_frames.split(",") if x.strip()}

    wording = resolve(root, a.wording, fallback=True)
    if not wording.exists():
        print(f"{a.wording}:0:MISSING: wording table file not found"); sys.exit(2)
    dontsay = parse_dontsay(wording)
    if not dontsay:
        print(f"{rel(wording, root)}:0:WORDING: no Don't-say phrases parsed under 'Wording rules'"); sys.exit(2)
    print(f"NOTE: {len(dontsay)} Don't-say phrases from {rel(wording, root)}")
    rules = {}; rp = resolve(root, a.rules, fallback=True)
    if rp.exists():
        rules = json.loads(rp.read_text(encoding="utf-8")).get("categories", {})
        print(f"NOTE: {len(rules)} C1-C20 categories from {rel(rp, root)}")
    else:
        print(f"NOTE: {a.rules} absent; scanning with RL2, DONTSAY, DRUG and SHAME rules only (C1-C20 not applied)")
    dp = resolve(root, a.drug_names)
    if dp.exists():
        drugs = parse_drugs(dp); print(f"NOTE: {len(drugs)} drug names from {rel(dp, root)}")
    else:
        drugs = BUILTIN_DRUGS; print(f"NOTE: {a.drug_names} absent; using the built-in list of {len(drugs)} ADHD medicine names and classes")
    sc = Scanner(dontsay, rules, drugs)

    sets = []; missing = []
    if a.strings:
        d = resolve(root, a.strings)
        if not d.is_dir():
            missing.append(a.strings)
        else:
            sets.append(("strings", None, read_strings(d, root)))
    if a.input or (not a.strings and not a.replacements):
        p = resolve(root, a.input or "docs/figma/text-layers.csv")
        if not p.exists():
            missing.append(rel(p, root))
        else:
            sets.append(("text-layers", rel(p, root), read_csv(p, discreet)))
    if a.replacements:
        p = resolve(root, a.replacements)
        if not p.exists():
            missing.append(rel(p, root))
        else:
            sets.append(("replacements", rel(p, root), read_replacements(p)))
    for m in missing:
        print(f"{m}:0:MISSING: input not found")
    if missing:
        sys.exit(2)

    hits = []; scanned = 0; frames = set()
    for kind, fname, rows in sets:
        for r in rows:
            scanned += 1; frames.add(r["frame"])
            for rule, cat, msg in sc.scan(r["text"], r["glance"], kind == "replacements", r.get("orig")):
                f = r.get("file") or fname
                hits.append((f, r["line"], rule, cat, r["node"], r["frame_name"], r["text"], msg))
                print(f"{f}:{r['line']}:{rule}: {msg} [node {r['node']}]")
    ne = resolve(root, "docs/figma/text-layers.NOT-EXTRACTED.md"); not_ext = []
    if ne.exists() and any(k == "text-layers" for k, _, _ in sets):
        for l in ne.read_text(encoding="utf-8").split("\n"):
            if (l.strip().startswith("|") and not is_sep(l) and not re.search(r"\breason\b", l, re.I)) or re.match(r"^\s*[-*]\s+", l):
                not_ext.append(l.strip().strip("|").strip())
    out = resolve(root, a.output); out.parent.mkdir(parents=True, exist_ok=True)
    rep = ["# Copy scan", "", f"Generated by scripts/copy_scan.py. Sets: {', '.join(k + (' (' + f + ')' if f else '') for k, f, _ in sets)}.",
           f"Rules: RL2, DONTSAY ({len(dontsay)} phrases), {('C1-C20 (' + str(len(rules)) + ' categories)') if rules else 'C1-C20 not applied (scripts/copy_rules.json absent)'}, DRUG ({len(drugs)} names), SHAME" + (", EXCLAIM, PRAISE, CLINICAL, AUSPELL, LENGTH (replacements)" if a.replacements else "") + ".", "",
           "| Measure | Count |", "|---|---|", f"| Rows scanned | {scanned} |", f"| Frames | {len(frames)} |",
           f"| Frames not extracted | {len(not_ext)} |", f"| Hits | {len(hits)} |", ""]
    if not_ext:
        rep += ["## Frames not extracted", ""] + [f"- {esc(x)}" for x in not_ext] + [""]
    rep += ["## Hits", ""]
    if hits:
        rep += ["| # | Location | Rule | Category | Node id | Frame | Text | Finding |", "|---|---|---|---|---|---|---|---|"]
        for n, (f, ln, rule, cat, node, fr, text, msg) in enumerate(hits, 1):
            rep.append(f"| {n} | {esc(str(f))}:{ln} | {rule} | {cat} | {esc(node)} | {esc(fr) or 'none'} | `{esc(text)}` | {esc(msg)} |")
    else:
        rep.append("No hits.")
    rep += ["", "<!-- END OF FILE -->", ""]
    out.write_text("\n".join(rep), encoding="utf-8")
    print(f"copy_scan: {scanned} rows scanned, {len(frames)} frames, {len(not_ext)} frames not extracted, {len(hits)} hits; report {rel(out, root)}")
    sys.exit(1 if hits else 0)


if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
