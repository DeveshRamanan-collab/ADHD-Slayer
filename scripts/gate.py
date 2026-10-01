#!/usr/bin/env python3
"""gate.py G<n> [--loop <n>] [--root DIR] [--items LIST] [--file-key KEY] [--regenerate]

Runs the mechanical items of the OM-4 gate row for G0..G5 (docs/AGENT_RULES.md OM-4; spec: prompts/06_SCRIPT_SPECS.md
"gate.py") and prints the 04-T3 Checklist table (| # | Check | Method | Result | Evidence |) for the reviewer to complete,
then every failure as `file:line:RULE: message` (suffix [HARD-FAIL] when it belongs to an OM-4 hard-fail class).
Exit 0 = every item PASS; 1 = any FAIL; 2 = usage error.

Options
  --loop <n>       loop number (1-3) recorded in the report header.
  --root DIR       repository root to check (default: the parent of scripts/); used for fixture runs.
  --items LIST     comma-separated item labels to run (e.g. 1,6,C,REDLINE); default all items of the gate.
  --file-key KEY   Figma file key for G1/G2 (default: the docs/figma/raw/<key>/ folder that holds nodes.json files).
  --regenerate     G1 item 6 / G2 item 4: run extract_text.py / copy_scan.py before checking their outputs
                   (default: check the committed outputs only, so the gate never modifies the tree).

Items (labels as printed in the # column)
  G0 1 PREFLIGHT rows: status in {OK, MISSING, UNVERIFIABLE}; each row has an [EV: path] that exists; RUN-SURVIVAL line.
     2 TOOL_CAPABILITY_AUDIT: Tier A entries + Tier B rows = unique ITEM lines in docs/evidence/p00/discovery-*.log;
       every PRIMARY/SECONDARY/REVIEW entry cites a harmless-call [EV:] that exists and is not the discovery log.
     3 TOOL_STRATEGY: a table row with >=1 capability for each of the 16 Phase 0.4 stages; a multi-agent plan heading;
       the file-ownership map lists every docs/MANIFEST.md path (<...> segments in the map match one path segment).
     4 Every hook script named in prompts/05_SETTINGS_AND_HOOKS.md exists and the newest docs/evidence/p00/hooks-*.log
       that tests it has >=1 [PASS] line and no [FAIL] line for it (log has run_logged header/footer).
     5 scripts/validate_docs.py --manifest exits 0.
     6 Read-only git: `git log` has a commit whose subject starts "Phase 0"; `git status --porcelain` is empty.
     7 Every PREFLIGHT MISSING row cites a B-nnn defined in docs/BLOCKERS.md, or a BLOCKERS entry names the row
       (a UA-nnn, backticked token or path from the row appears in it).
     8 SOURCE_INVENTORY lists every K.2 input as present (SHA-256 prefix matches the file now) or missing (file absent,
       or created after the inventory was generated).
  G1 1 FIGMA_VERSION_LOCK has a root fingerprint and every nodes.json page fingerprint; PROGRESS LOCK_FINGERPRINT matches.
     2 figma_reconcile.py <key> --strict exits 0.   3 no [NOT YET READ] row unless metadata-only-variant naming a defined
       base-frame row.   4 validate_docs.py exits 0.   5 ledger vs cache: every ok row has its cache file; no untagged
       double read; every reader is the designated reader.   6 text-layers.csv has rows; NOT-EXTRACTED lists only
       metadata-only-variant frames (extract_text.py must exist).   7 validate_analysis.py passes for every page analysis.
  G2 1 RECONCILIATION sections; Document-only dispositions; Figma-only/in-both rows cite a FEAT- with Source in PRODUCT_SPEC.
     2 Contradictions >=1 row or NONE FOUND with [EV:].   3 every FIGMA-GAP- id in Missing states.   4 copy-scan rows
       scanned = text-layers.csv rows; every hit has a node id (copy_scan.py must exist).   5 CHANGELOG covers every
       Changed/Figma-only/Document-only feature.   6 design_doc_xref.py runs; every unfound item listed [DESIGN-DOC-ONLY].
  G3 1 FEAT Source + acceptance criteria citations + TEST-/N/A.   2 SCR->UI, UI->DATA, DATA Phase 7 columns, internalOnly
       pharmacology fields, 8.1.3 fields never non-device residency.   3 INV-RL1/2/6/7/8 exist with TEST-.   4 IOS- columns,
       verified date, [EV:] excerpt containing the minimum iOS version.   5 check_facts.py.   6 ARCHITECTURE dependencies
       have a boring alternative and CHALLENGED: accepted|rejected.   7 DESIGN_SYSTEM tokens cite a node or cache path;
       handoff differences section.   8 check_names.py.   9 LEGAL- rows: all 11.2 columns, class, confidence, Enforced-in
       ids resolve.
  G4 1 validate_docs --manifest.  2 check_facts.  3 check_tasks.  4 trace.py; no "N/A (UI test: TESTING_STRATEGY,
       Phase 14)" left in PRODUCT_SPEC.  5 CLAUDE.md, PROGRESS.md, DEVESH_BUILD_GUIDE.md exist, end marker, validator.
       6 every numbered guide step has a 'what you should see' line.  7 validator EV/EVLOG rules only.  8 SPEC_CHECKLIST
       items ticked or RESIDUAL-; drift report under docs/evidence/.  9 CLAUDE.md starts with the Phase 0 bootstrap block
       (read via `git show`), carries RL-1..RL-9 and a NEVER list.  10 check_scope.sh.  11 au_spelling.py.  12 REL- Blocks
       rows name docs/evidence/release/; every Phase 11.7 Q-L id is in OPEN_QUESTIONS.
  G5 1 COMPLETENESS_AUDIT items 1-12 PASS, or FAIL with a RESIDUAL- (all columns, owner build-phase|Devesh, file#section,
       not a hard-fail class).
  All gates: C  PROGRESS header counters (13 keys; QUESTIONS_ASKED_TO_USER 0; TURNS_ENDED_WAITING 0; LOCK_FINGERPRINT
       set from G1).   G3-G5: REDLINE  the RL-1..RL-9 table (from the line starting `| RL-1` to the line starting
       `| RL-9`) is byte-identical (SHA-256) across the seven carrying documents present at that gate.
A sibling script that is absent makes its item FAIL with `scripts/<name>:0:SCRIPT: script missing`.
Git is used read-only (`git log`, `git status`, `git show`). Python 3 standard library only."""
import sys, os, re, csv, glob, hashlib, subprocess, datetime, pathlib, argparse

SCRIPTS = pathlib.Path(__file__).resolve().parent
EMPTY = {"", "—", "-", "–", "n/a", "N/A", "TBC", "?"}
FENCE = "`" * 3
EV_RE = re.compile(r"\[EV:\s*(docs/evidence/[^\]\s]+)\s*\]")
LINE_RE = re.compile(r"^(?P<f>[^\s:][^:]*):(?P<l>\d+):(?P<r>[A-Za-z][A-Za-z0-9_.-]*):\s?(?P<m>.*)$")
HARD_RULES = {"END", "PHRASE", "MISSING", "SRC", "NOTYETREAD", "NOSOURCE", "HARDFAIL"}
ID_ANY = re.compile(r"\b(?:[A-Z]{1,6}(?:-[A-Z]{1,6})?-\d{2,4}|INV-RL\d)\b")
STAGES = ["Inspect Figma", "Extract design system", "Audit interactions", "Research Apple API feasibility",
          "Define architecture", "Write Swift", "Build engine tests", "Run Xcode builds",
          "Runtime verification on Simulator/device", "Git operations", "Review diffs", "Security audit",
          "Privacy/legal research", "Accessibility review", "Drift detection", "TestFlight preparation"]
K2_FALLBACK = ["docs/design/DESIGN_SPEC.md", "docs/design/decisions.md", "docs/design/figma-usage.md",
               "docs/design/handoff.md", "docs/design/metrics.md", "docs/design/usability-test-plan.md",
               "SPEC_CHECKLIST.md", "research/adhd_struggles.md", "research/interventions_evidence.md",
               "research/medication_pharmacology.md", "research/regulation_privacy_safety.md",
               "research/apple_platform.md", "research/learning_and_lifestyles.md",
               "research/competitors_failure_modes.md", "prompts/figma_design_prompt.md", "prompts/figma_urls.md"]
PROGRESS_KEYS = ["RUN_STATUS", "RUN_STARTED", "UPDATED", "CURRENT_PHASE", "NEXT_ACTION", "RETRY_AFTER",
                 "LOCK_FINGERPRINT", "FIGMA_EPOCH_READS", "LAST_GATE", "OPEN_BLOCKERS", "QUESTIONS_ASKED_TO_USER",
                 "TURNS_ENDED_WAITING", "RUN-SURVIVAL"]
RUN_STATUSES = {"RUNNING", "WAITING_FOR_FIGMA_RESET", "STALLED", "COMPLETE", "COMPLETE_WITH_RESIDUALS",
                "HALTED_USER_ACTION_REQUIRED", "HALTED_HARD_FAIL"}
TIME_OK = re.compile(r"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-]\d{2}:?\d{2})$")
REDLINE_DOCS = ["docs/PRODUCT_SPEC.md", "docs/ENGINE_SPEC.md", "docs/COPY_REVIEW.md", "docs/LEGAL_PRIVACY_SAFETY.md",
                "docs/CLAUDE_CODE_INSTRUCTIONS.md", "CLAUDE.md", "docs/AGENT_RULES.md"]
MANIFEST_PATHS = set()   # filled in main() from docs/MANIFEST.md
SKIP_DEFS = ("docs/evidence/", "docs/figma/raw/", "docs/agents/", "docs/parts/")
HARD_TEXT = re.compile(r"red-line hit|end marker|truncation|NOT YET READ|UNRESOLVED|MANIFEST deliverable|"
                       r"missing deliverable|no Source", re.I)
SENSITIVE_813 = re.compile(r"medication|dose|check-?in|brain-?weather|focus.?window|sleep|workout|heart|discreet|"
                           r"consent|confirmedAdult|free text|signpost", re.I)
PHARMA = re.compile(r"onset|\bpeak|wear-?off|wearing off|half-life|kicks in|duration estimate|medication class", re.I)


# ---------------------------------------------------------------- helpers
class Item:
    def __init__(self, label, check, method):
        self.label, self.check, self.method = label, check, method
        self.fails, self.evidence, self.notes = [], [], []

    def fail(self, f, line, rule, msg, hard=None):
        if hard is None:   # MISSING is a hard-fail class only for a docs/MANIFEST.md deliverable
            hard = (rule in HARD_RULES and rule != "MISSING") or (rule == "MISSING" and str(f) in MANIFEST_PATHS)
        self.fails.append((str(f), int(line), rule, str(msg), hard))

    def ev(self, text):
        self.evidence.append(text)

    @property
    def result(self):
        if not self.fails:
            return "PASS"
        return "FAIL (HARD-FAIL class)" if any(h for *_, h in self.fails) else "FAIL"


class Ctx:
    def __init__(self, root, gate, file_key, regenerate):
        self.root, self.gate, self.file_key_opt, self.regenerate = root, gate, file_key, regenerate
        self._defs = None

    def p(self, rel):
        return self.root / rel

    def read(self, rel):
        fp = self.p(rel)
        try:
            return fp.read_text(encoding="utf-8", errors="replace")
        except (FileNotFoundError, IsADirectoryError):
            return None

    def exists(self, rel):
        return self.p(rel).exists()

    def run_script(self, name, args):
        sp = SCRIPTS / name
        if not sp.exists():
            return None
        cmd = ([sys.executable, str(sp)] if name.endswith(".py") else ["bash", str(sp)]) + list(args)
        try:
            r = subprocess.run(cmd, cwd=str(self.root), stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, timeout=600)
            return r.returncode, r.stdout
        except subprocess.TimeoutExpired:
            return 124, "timeout after 600 s"

    def git(self, *args):
        try:
            r = subprocess.run(["git"] + list(args), cwd=str(self.root), stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True, timeout=120)
            return r.returncode, r.stdout, r.stderr
        except Exception as e:  # git absent
            return 127, "", str(e)

    def defs(self):
        """Every id definition (heading or first table cell, bold or plain) across the Markdown deliverables."""
        if self._defs is None:
            d = {}
            files = [self.p("CLAUDE.md")] + (sorted(self.p("docs").rglob("*.md")) if self.p("docs").exists() else [])
            for fp in files:
                if not fp.exists():
                    continue
                rel = str(fp.relative_to(self.root))
                if rel.startswith(SKIP_DEFS):
                    continue
                for i, l in enumerate(masked_lines(fp.read_text(encoding="utf-8", errors="replace")), 1):
                    for ident in line_defs(l):
                        d.setdefault(ident, (rel, i))
            self._defs = d
        return self._defs


def masked_lines(text):
    """Lines with fenced-code regions blanked (tables and ids inside fences are not parsed)."""
    out, fence = [], False
    for l in text.split("\n"):
        if l.lstrip().startswith(FENCE):
            fence = not fence
            out.append("")
            continue
        out.append("" if fence else l)
    return out


def line_defs(l):
    m = re.match(r"^#{2,5}\s+\**([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-\d{2,4}|INV-RL\d)\b", l)
    if m:
        return [m.group(1)]
    m = re.match(r"^\|\s*\**\s*([A-Z][A-Z0-9]*(?:-[A-Z0-9]+)*-\d{2,4}|INV-RL\d)\s*\**\s*\|", l)
    return [m.group(1)] if m else []


def is_row(l):
    return l.strip().startswith("|")


def is_sep(l):
    return bool(re.match(r"^\|\s*:?-{2,}", l.strip()))


def cells(l):
    s = l.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|"):
        s = s[:-1]
    return [c.strip() for c in s.split("|")]


def tables(text, start=0, lines=None):
    """Markdown tables: [{'line': header line no, 'header': [...], 'rows': [(line no, cells, raw)]}]."""
    ls = lines if lines is not None else masked_lines(text)
    out, i = [], 0
    while i < len(ls) - 1:
        if is_row(ls[i]) and is_sep(ls[i + 1]):
            hdr, rows, j = cells(ls[i]), [], i + 2
            while j < len(ls) and is_row(ls[j]):
                if not is_sep(ls[j]):
                    rows.append((start + j + 1, cells(ls[j]), ls[j]))
                j += 1
            out.append({"line": start + i + 1, "header": hdr, "rows": rows})
            i = j
        else:
            i += 1
    return out


def col(header, *names):
    for n in names:
        for i, h in enumerate(header):
            if n.lower() in h.lower():
                return i
    return None


def cell(c, i):
    return c[i] if i is not None and i < len(c) else ""


def is_empty(c):
    s = c.strip().strip("*").strip()
    if s in EMPTY:
        return True
    m = re.match(r"^N/A\s*\((.*)\)$", s, re.I)
    if m:
        return len(m.group(1).split()) < 3
    return False


def section(text, heading_re):
    """(first line no, [lines]) of the first heading matching heading_re up to the next heading of the same or higher level."""
    ls = masked_lines(text)
    for i, l in enumerate(ls):
        m = re.match(r"^(#{1,6})\s+(.*)$", l)
        if m and re.search(heading_re, m.group(2), re.I):
            lvl, body = len(m.group(1)), []
            for j in range(i + 1, len(ls)):
                m2 = re.match(r"^(#{1,6})\s", ls[j])
                if m2 and len(m2.group(1)) <= lvl:
                    break
                body.append(ls[j])
            return i + 2, body
    return None, None


def norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower().replace("`", ""))


def strip_md(s):
    return s.replace("`", "").replace("*", "").strip()


def sha(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def absorb(item, name, res, ok_codes=(0,)):
    """Fold a sibling script's result into an item: missing → SCRIPT FAIL; non-zero → its file:line:RULE lines."""
    if res is None:
        item.fail("scripts/" + name, 0, "SCRIPT", "script missing")
        return False
    code, out = res
    lines = [l for l in out.splitlines() if LINE_RE.match(l)]
    tail = out.strip().splitlines()[-1] if out.strip() else "no output"
    item.ev(f"scripts/{name} exit {code}: {tail[:120]}")
    if code in ok_codes:
        return True
    if not lines:
        item.fail("scripts/" + name, 0, "SCRIPT", f"exit {code}: {tail[:200]}")
    for l in lines[:300]:
        m = LINE_RE.match(l)
        item.fail(m.group("f"), m.group("l"), m.group("r"), m.group("m"))
    if len(lines) > 300:
        item.fail("scripts/" + name, 0, "SCRIPT", f"{len(lines) - 300} further failure lines not shown; run the script directly")
    return False


def need(item, ctx, rel):
    t = ctx.read(rel)
    if t is None:
        item.fail(rel, 0, "MISSING", "file absent")
    return t


def progress_field(ctx, key):
    t = ctx.read("docs/PROGRESS.md") or ""
    m = re.search(r"(?m)^" + re.escape(key) + r":[ \t]*(.*)$", t)
    return m.group(1).strip() if m else None


def manifest_rows(ctx):
    t = ctx.read("docs/MANIFEST.md") or ""
    out = []
    for tb in tables(t):
        for ln, c, raw in tb["rows"]:
            p = strip_md(c[0]) if c else ""
            if re.match(r"^(docs/|CLAUDE\.md|scripts/)", p):
                out.append((ln, p, c))
    return out


def figma_keys(ctx):
    raw = ctx.p("docs/figma/raw")
    keys = []
    if raw.exists():
        for d in sorted(raw.iterdir()):
            if d.is_dir() and d.name not in ("FIXTUREKEY", "unknown"):
                keys.append((len(list(d.glob("*/nodes.json"))), d.name))
    if ctx.file_key_opt:
        return ctx.file_key_opt
    keys.sort(reverse=True)
    return keys[0][1] if keys else None


# ---------------------------------------------------------------- common items
def item_counters(ctx):
    it = Item("C", "PROGRESS header counters: 13 keys present; QUESTIONS_ASKED_TO_USER 0; TURNS_ENDED_WAITING 0; "
              "RUN_STATUS valid; UPDATED with seconds and offset" + ("; LOCK_FINGERPRINT set" if ctx.gate >= 1 else ""),
              "gate.py C: parse docs/PROGRESS.md header")
    t = need(it, ctx, "docs/PROGRESS.md")
    if t is None:
        return it
    lines = t.split("\n")
    for k in PROGRESS_KEYS:
        ln = next((i for i, l in enumerate(lines, 1) if l.startswith(k + ":")), None)
        if ln is None:
            it.fail("docs/PROGRESS.md", 1, "G%d.C" % ctx.gate, f"header key {k} missing")
    def chk(key, pred, msg):
        v = progress_field(ctx, key)
        ln = next((i for i, l in enumerate(lines, 1) if l.startswith(key + ":")), 1)
        if v is not None and not pred(v):
            it.fail("docs/PROGRESS.md", ln, "G%d.C" % ctx.gate, f"{key}: {v} — {msg}")
    chk("QUESTIONS_ASKED_TO_USER", lambda v: v == "0", "must stay 0")
    chk("TURNS_ENDED_WAITING", lambda v: v == "0", "must stay 0")
    chk("RUN_STATUS", lambda v: v in RUN_STATUSES, "not a defined RUN_STATUS value")
    chk("UPDATED", lambda v: bool(TIME_OK.match(v)), "timestamp needs seconds and offset")
    chk("FIGMA_EPOCH_READS", lambda v: bool(re.match(r"^\d+/\d+$", v)), "format n/cap")
    if ctx.gate >= 1:
        chk("LOCK_FINGERPRINT", lambda v: bool(re.search(r"[0-9a-f]{16,64}", v)), "no lock fingerprint after G1")
    it.ev("docs/PROGRESS.md header")
    return it


def redline_extract(text):
    ls = text.split("\n")
    s = next((i for i, l in enumerate(ls) if l.startswith("| RL-1")), None)
    if s is None:
        return None, None
    e = next((i for i in range(s, len(ls)) if ls[i].startswith("| RL-9")), None)
    if e is None:
        return None, None
    return s + 1, ls[s:e + 1]


def max_gate(cellv):
    g = [int(x) for x in re.findall(r"G([0-5])", cellv)]
    return max(g) if g else None


def item_redline(ctx):
    it = Item("REDLINE", "RL-1..RL-9 table byte-identical (SHA-256) in every carrying document present at this gate "
              "(K.4: PRODUCT_SPEC, ENGINE_SPEC, COPY_REVIEW, LEGAL_PRIVACY_SAFETY, CLAUDE_CODE_INSTRUCTIONS, CLAUDE.md, AGENT_RULES)",
              "gate.py REDLINE: extract the lines from the RL-1 row to the RL-9 row, sha256, compare with docs/AGENT_RULES.md")
    gates = {}
    for ln, p, c in manifest_rows(ctx):
        g = max_gate(" ".join(c[1:]))
        if g is not None:
            gates[p] = max(g, gates.get(p, 0))
    found = {}
    for rel in REDLINE_DOCS:
        due = gates.get(rel)
        t = ctx.read(rel)
        if t is None:
            if due is not None and due <= ctx.gate:
                it.notes.append(f"{rel} absent although due at G{due} (validate_docs reports MISSING)")
            elif due is None:
                it.notes.append(f"{rel} absent and not in docs/MANIFEST.md")
            continue
        due = 0 if due is None else due
        if due > ctx.gate:
            it.notes.append(f"{rel} present but due at G{due}; not compared at G{ctx.gate}")
            continue
        start, block = redline_extract(t)
        if block is None:
            it.fail(rel, 1, "REDLINE", "RL-1..RL-9 table not found (needs lines starting `| RL-1` through `| RL-9`)")
            continue
        found[rel] = (start, block, sha("\n".join(block)))
    if not found:
        it.fail("docs/AGENT_RULES.md", 0, "REDLINE", "no carrying document present")
        return it
    ref = "docs/AGENT_RULES.md" if "docs/AGENT_RULES.md" in found else sorted(found)[0]
    rs, rb, rh = found[ref]
    for rel, (s, b, h) in sorted(found.items()):
        it.ev(f"{rel}:{s} sha256 {h[:16]}")
        if h == rh:
            continue
        k = next((i for i in range(max(len(b), len(rb))) if i >= len(b) or i >= len(rb) or b[i] != rb[i]), 0)
        it.fail(rel, s + k, "REDLINE", f"differs from {ref}:{rs + k} (sha256 {h[:16]} vs {rh[:16]})")
    return it


# ---------------------------------------------------------------- G0
def g0_1(ctx):
    it = Item("1", "PREFLIGHT: every row's status in {OK, MISSING, UNVERIFIABLE} with an existing [EV:] path; RUN-SURVIVAL line",
              "gate.py G0.1: parse docs/PREFLIGHT.md tables")
    t = need(it, ctx, "docs/PREFLIGHT.md")
    if t is None:
        return it
    if not re.search(r"(?m)^RUN-SURVIVAL:", t):
        it.fail("docs/PREFLIGHT.md", 1, "G0.1", "RUN-SURVIVAL line missing")
    n = 0
    for tb in tables(t):
        st = col(tb["header"], "status")
        if st is None:
            it.fail("docs/PREFLIGHT.md", tb["line"], "G0.1", "table has no Status column")
            continue
        for ln, c, raw in tb["rows"]:
            n += 1
            s = strip_md(cell(c, st))
            if s not in ("OK", "MISSING", "UNVERIFIABLE"):
                it.fail("docs/PREFLIGHT.md", ln, "G0.1", f"status '{s}' not in OK/MISSING/UNVERIFIABLE")
            evs = EV_RE.findall(raw)
            if not evs:
                it.fail("docs/PREFLIGHT.md", ln, "G0.1", "row has no [EV: docs/evidence/...] path")
            for e in evs:
                if not ctx.exists(e):
                    it.fail("docs/PREFLIGHT.md", ln, "G0.1", f"evidence path missing: {e}")
    if n == 0:
        it.fail("docs/PREFLIGHT.md", 1, "G0.1", "no table rows found")
    it.ev(f"docs/PREFLIGHT.md ({n} rows)")
    return it


def g0_2(ctx):
    it = Item("2", "TOOL_CAPABILITY_AUDIT: Tier A entries + Tier B rows = discovery items; PRIMARY/SECONDARY/REVIEW entries have harmless-call [EV:]",
              "gate.py G0.2: count ### entries, Tier B rows, unique ITEM lines in docs/evidence/p00/discovery-*.log")
    rel = "docs/TOOL_CAPABILITY_AUDIT.md"
    t = need(it, ctx, rel)
    if t is None:
        return it
    sa, la = section(t, r"^Tier A")
    sb, lb = section(t, r"^Tier B")
    if la is None:
        it.fail(rel, 1, "G0.2", "no '## Tier A' section")
        la, sa = [], 1
    if lb is None:
        it.fail(rel, 1, "G0.2", "no '## Tier B' section")
        lb, sb = [], 1
    entries, cur = [], None
    for i, l in enumerate(la):
        m = re.match(r"^###\s+(.*)$", l)
        if m:
            cur = {"name": m.group(1).strip(), "line": sa + i, "cls": None, "ev": [], "evline": sa + i}
            entries.append(cur)
        elif cur is not None:
            mc = re.match(r"^-\s*Classification:\s*([A-Z][A-Z -]*?)(?:\s+—|\s*$)", l)
            if mc:
                cur["cls"] = mc.group(1).strip()
            if re.match(r"^-\s*Evidence:", l):
                cur["ev"], cur["evline"] = EV_RE.findall(l), sa + i
    b_rows = sum(len(tb["rows"]) for tb in tables("", start=sb - 1, lines=lb))
    logs = sorted(glob.glob(str(ctx.p("docs/evidence/p00/discovery-*.log"))))
    items = set()
    for lg in logs:
        for l in open(lg, encoding="utf-8", errors="replace"):
            if l.startswith("ITEM "):
                items.add(l.split(" | ")[0].strip())
    if not logs:
        it.fail("docs/evidence/p00", 0, "G0.2", "no discovery-*.log")
    if len(entries) + b_rows != len(items):
        it.fail(rel, sa, "G0.2", f"Tier A {len(entries)} + Tier B {b_rows} = {len(entries) + b_rows} != {len(items)} discovery items")
    for e in entries:
        if e["cls"] is None:
            it.fail(rel, e["line"], "G0.2", f"{e['name']}: no Classification line")
            continue
        if e["cls"].split()[0] in ("PRIMARY", "SECONDARY", "REVIEW", "REVIEW-VERIFICATION"):
            harmless = [p for p in e["ev"] if "/discovery-" not in p]
            if not harmless:
                it.fail(rel, e["evline"], "G0.2", f"{e['name']} ({e['cls']}): no harmless-call [EV:] (discovery listing does not count)")
            for p in e["ev"]:
                if not ctx.exists(p):
                    it.fail(rel, e["evline"], "G0.2", f"{e['name']}: evidence path missing: {p}")
    it.ev(f"{rel}: Tier A {len(entries)}, Tier B {b_rows}; discovery items {len(items)} in {len(logs)} log(s)")
    return it


def g0_3(ctx):
    it = Item("3", "TOOL_STRATEGY: >=1 capability for every 0.4 stage; multi-agent plan; file-ownership map covers every MANIFEST path",
              "gate.py G0.3: stage rows, plan heading, ownership-map first cells vs docs/MANIFEST.md")
    rel = "docs/TOOL_STRATEGY.md"
    t = need(it, ctx, rel)
    if t is None:
        return it
    rows = [(ln, c) for tb in tables(t) for ln, c, raw in tb["rows"]]
    audit = ctx.read("docs/TOOL_CAPABILITY_AUDIT.md") or ""
    audit_rows = {norm(c[0]): ln for tb in tables(audit) for ln, c, raw in tb["rows"] if c}
    for st in STAGES:
        hit = [(ln, c) for ln, c in rows if c and norm(c[0]) == norm(st) and any(not is_empty(x) for x in c[1:])]
        if not hit:
            where = f"; the stage table row is in docs/TOOL_CAPABILITY_AUDIT.md:{audit_rows[norm(st)]}" if norm(st) in audit_rows else ""
            it.fail(rel, 1, "G0.3", f"stage '{st}' has no capability row in TOOL_STRATEGY.md{where}")
    if not re.search(r"(?mi)^#{1,6}.*multi-agent", t):
        it.fail(rel, 1, "G0.3", "no multi-agent operating plan heading")
    s, body = section(t, r"ownership")
    if body is None:
        it.fail(rel, 1, "G0.3", "no file-ownership map section")
        return it
    mapped = set()
    for tb in tables("", start=s - 1, lines=body):
        for ln, c, raw in tb["rows"]:
            if c:
                mapped.add(strip_md(c[0]))
    pats = [re.compile("^" + re.sub(r"<[^>]+>", "[^/]+", re.escape(m).replace(r"\<", "<").replace(r"\>", ">")) + "$")
            for m in mapped if "<" in m]
    man = manifest_rows(ctx)
    if not man:
        it.fail("docs/MANIFEST.md", 0, "G0.3", "no manifest rows")
    for ln, p, c in man:
        if p not in mapped and not any(r.match(p) for r in pats):
            it.fail("docs/MANIFEST.md", ln, "G0.3", f"{p} not in the TOOL_STRATEGY.md ownership map")
    it.ev(f"{rel}: {len(STAGES)} stages checked; ownership map {len(mapped)} paths; MANIFEST {len(man)} paths")
    return it


def g0_4(ctx):
    it = Item("4", "Every hook script in prompts/05_SETTINGS_AND_HOOKS.md has a passing test in docs/evidence/p00/hooks-*.log",
              "gate.py G0.4: [PASS]/[FAIL] lines per hook in the newest log that tests it")
    spec = ctx.read("prompts/05_SETTINGS_AND_HOOKS.md")
    if spec is None:
        it.fail("prompts/05_SETTINGS_AND_HOOKS.md", 0, "MISSING", "file absent")
        return it
    hooks = []
    for h in re.findall(r"scripts/hooks/([A-Za-z0-9_]+)\.sh", spec):
        if h != "_lib" and h not in hooks:
            hooks.append(h)
    def ts(p):
        m = re.search(r"(\d{8}T\d{6})", p)
        return m.group(1) if m else ""
    logs = sorted(glob.glob(str(ctx.p("docs/evidence/p00/hooks-*.log"))), key=ts)
    parsed = []
    for lg in logs:
        txt = open(lg, encoding="utf-8", errors="replace").read()
        rel = os.path.relpath(lg, ctx.root)
        res = [(m.group(1), m.group(2), i) for i, l in enumerate(txt.split("\n"), 1)
               for m in [re.match(r"^\[(PASS|FAIL)\]\s+([A-Za-z0-9_]+)", l)] if m]
        parsed.append((rel, txt, res))
    if not logs:
        it.fail("docs/evidence/p00", 0, "G0.4", "no hooks-*.log")
    for h in hooks:
        if not ctx.exists(f"scripts/hooks/{h}.sh"):
            it.fail(f"scripts/hooks/{h}.sh", 0, "G0.4", "hook script missing")
        cand = [(rel, txt, [r for r in res if r[1] == h]) for rel, txt, res in parsed]
        cand = [x for x in cand if x[2]]
        if not cand:
            it.fail("prompts/05_SETTINGS_AND_HOOKS.md", 0, "G0.4", f"{h}.sh: no test line in any docs/evidence/p00/hooks-*.log")
            continue
        rel, txt, res = cand[-1]
        if "# cmd:" not in txt[:400] or "# exit:" not in txt[-400:]:
            it.fail(rel, 1, "G0.4", "log lacks run_logged header/footer")
        for kind, _, ln in res:
            if kind == "FAIL":
                it.fail(rel, ln, "G0.4", f"{h}.sh test failed in its newest log")
        if not any(k == "PASS" for k, _, _ in res):
            it.fail(rel, 0, "G0.4", f"{h}.sh: no [PASS] line")
    it.ev(f"{len(hooks)} hooks from prompts/05; {len(logs)} hooks log(s), newest {os.path.relpath(logs[-1], ctx.root) if logs else 'none'}")
    return it


def g_validate_manifest(ctx, label, check="scripts/validate_docs.py --manifest exits 0"):
    it = Item(label, check, "scripts/validate_docs.py --manifest")
    absorb(it, "validate_docs.py", ctx.run_script("validate_docs.py", ["--manifest"]))
    return it


def g0_6(ctx):
    it = Item("6", "git log shows the Phase 0 commit; git status --porcelain empty",
              "gate.py G0.6: read-only `git log --format=%h %s`, `git status --porcelain`")
    code, out, err = ctx.git("log", "--format=%h %s")
    if code != 0:
        it.fail(".git", 0, "G0.6", f"git log failed: {err.strip()[:160]}")
    else:
        subj = [l for l in out.splitlines() if re.match(r"^\S+ Phase 0(:|\s|$)", l)]
        if not subj:
            it.fail(".git", 0, "G0.6", "no commit whose subject starts 'Phase 0' (expected 'Phase 0: bootstrap, preflight, tool audit, enforcement tooling')")
        else:
            it.ev(f"Phase 0 commit {subj[0][:60]}")
    code, out, err = ctx.git("status", "--porcelain")
    if code != 0:
        it.fail(".git", 0, "G0.6", f"git status failed: {err.strip()[:160]}")
    else:
        def _inflight(l):  # the run_logged log of this very gate run (untracked, no footer yet) is not a dirty tree
            path = l[3:].strip()
            if not (l.startswith("??") and path.startswith("docs/evidence/") and path.endswith(".log")): return False
            try: return "# exit:" not in (ctx.root / path).read_text(encoding="utf-8", errors="replace")[-400:]
            except Exception: return False
        dirty = [l for l in out.splitlines() if l.strip() and not _inflight(l)]
        for l in dirty[:40]:
            it.fail(l[3:].strip() or ".", 0, "G0.6", f"uncommitted change ({l[:2].strip()})")
        if len(dirty) > 40:
            it.fail(".", 0, "G0.6", f"{len(dirty) - 40} further uncommitted paths")
        it.ev(f"git status --porcelain: {len(dirty)} entries")
    return it


def g0_7(ctx):
    it = Item("7", "Every PREFLIGHT MISSING row has a B-nnn (on the row, or a docs/BLOCKERS.md entry naming it)",
              "gate.py G0.7: B- ids on MISSING rows resolved against docs/BLOCKERS.md headings; else token match")
    t = need(it, ctx, "docs/PREFLIGHT.md")
    b = need(it, ctx, "docs/BLOCKERS.md")
    if t is None or b is None:
        return it
    defined = set(re.findall(r"(?m)^#{2,4}\s+(B-\d{3})\b", b))
    entries = re.split(r"(?m)^(?=#{2,4}\s+B-\d{3}\b)", b)
    n = 0
    for tb in tables(t):
        st = col(tb["header"], "status")
        for ln, c, raw in tb["rows"]:
            if strip_md(cell(c, st)) != "MISSING":
                continue
            n += 1
            ids = re.findall(r"\bB-\d{3}\b", raw)
            if ids:
                for i in ids:
                    if i not in defined:
                        it.fail("docs/PREFLIGHT.md", ln, "G0.7", f"{i} cited but not defined in docs/BLOCKERS.md")
                continue
            toks = set(re.findall(r"\bUA-\d{3}\b", raw))
            toks |= {x for x in re.findall(r"`([^`]{4,})`", raw)}
            toks |= set(re.findall(r"\b(?:docs|research|prompts|scripts)/[\w./-]+", raw))
            hit = [e.split("\n", 1)[0].strip("# ").split(" ")[0] for e in entries
                   if re.match(r"#{2,4}\s+B-\d{3}", e) and any(x in e for x in toks)]
            if not hit:
                it.fail("docs/PREFLIGHT.md", ln, "G0.7", f"MISSING row '{strip_md(c[0])[:70]}' has no B-nnn")
    it.ev(f"docs/PREFLIGHT.md: {n} MISSING rows; docs/BLOCKERS.md: {len(defined)} B- entries")
    return it


def k2_expected(ctx):
    t = ctx.read("prompts/01_MASTER_PLANNING_PROMPT.md")
    exp = []
    if t:
        s, body = section(t, r"^K\.2")
        if body:
            for tok in re.findall(r"`([\w./ -]+\.(?:md|pdf))`", "\n".join(body)):
                if "/" in tok or tok == "SPEC_CHECKLIST.md":
                    exp.append(tok)
    if not exp:
        exp = list(K2_FALLBACK)
    exp += sorted(os.path.relpath(p, ctx.root) for p in glob.glob(str(ctx.p("prompts/0[1-6]_*.md"))))
    seen, out = set(), []
    for e in exp:
        if e not in seen:
            seen.add(e)
            out.append(e)
    return out


def g0_8(ctx):
    it = Item("8", "SOURCE_INVENTORY lists every expected input (K.2) as present (SHA-256) or missing",
              "gate.py G0.8: expected-inputs table vs K.2 list; SHA-256 prefix recomputed")
    rel = "docs/SOURCE_INVENTORY.md"
    t = need(it, ctx, rel)
    if t is None:
        return it
    gm = re.search(r"Generated:\s*(\S+)", t)
    gen = None
    if gm:
        try:
            gen = datetime.datetime.strptime(gm.group(1), "%Y-%m-%dT%H:%M:%S%z").timestamp()
        except ValueError:
            gen = None
    rows = {}
    for tb in tables(t):
        st, sh = col(tb["header"], "status"), col(tb["header"], "sha")
        if st is None:
            continue
        for ln, c, raw in tb["rows"]:
            rows.setdefault(strip_md(c[0]), (ln, strip_md(cell(c, st)).lower(), strip_md(cell(c, sh))))
    exp = k2_expected(ctx)
    for e in exp:
        if e not in rows:
            it.fail(rel, 0, "G0.8", f"expected input {e} not listed")
            continue
        ln, status, hx = rows[e]
        fp = ctx.p(e)
        if status == "present":
            if not fp.is_file():
                it.fail(rel, ln, "G0.8", f"{e} listed present but absent")
            elif not re.match(r"^[0-9a-f]{16,64}$", hx):
                it.fail(rel, ln, "G0.8", f"{e}: no SHA-256")
            else:
                actual = hashlib.sha256(fp.read_bytes()).hexdigest()
                if not actual.startswith(hx):
                    it.fail(rel, ln, "G0.8", f"{e}: SHA-256 {hx} != current {actual[:len(hx)]} (immutable input changed)")
        elif status == "missing":
            if fp.exists():
                if gen is not None and fp.stat().st_mtime > gen:
                    it.notes.append(f"{e} listed missing; a file of that name was created after the inventory")
                else:
                    it.fail(rel, ln, "G0.8", f"{e} listed missing but present")
        else:
            it.fail(rel, ln, "G0.8", f"{e}: status '{status}' not present/missing")
    it.ev(f"{rel}: {len(exp)} expected inputs checked")
    return it


# ---------------------------------------------------------------- G1
def g1_1(ctx):
    it = Item("1", "FIGMA_VERSION_LOCK has canonical fingerprints for root and every page; PROGRESS LOCK_FINGERPRINT matches",
              "gate.py G1.1: nodes.json fingerprint fields vs docs/FIGMA_VERSION_LOCK.md")
    rel = "docs/FIGMA_VERSION_LOCK.md"
    t = need(it, ctx, rel)
    key = figma_keys(ctx)
    if t is None:
        return it
    root_fp = None
    for i, l in enumerate(t.split("\n"), 1):
        if re.search(r"\broot\b", l, re.I):
            m = re.search(r"\b([0-9a-f]{64})\b", l)
            if m:
                root_fp = (i, m.group(1))
                break
    if root_fp is None:
        it.fail(rel, 1, "G1.1", "no root fingerprint (64 hex on a line naming root)")
    pages = sorted(glob.glob(str(ctx.p(f"docs/figma/raw/{key}/*/nodes.json")))) if key else []
    if not pages:
        it.fail(f"docs/figma/raw/{key or '<key>'}", 0, "G1.1", "no nodes.json pages")
    import json
    for pg in pages:
        prel = os.path.relpath(pg, ctx.root)
        try:
            fpv = json.load(open(pg, encoding="utf-8")).get("fingerprint")
        except Exception as e:
            it.fail(prel, 0, "G1.1", f"unreadable nodes.json: {e.__class__.__name__}")
            continue
        if not fpv:
            it.fail(prel, 0, "G1.1", "no fingerprint field (run figma_fingerprint.py)")
        elif fpv not in t:
            it.fail(rel, 0, "G1.1", f"page fingerprint {fpv[:16]} of {prel} not in the lock")
    lf = progress_field(ctx, "LOCK_FINGERPRINT")
    if root_fp and (not lf or root_fp[1] not in lf and not root_fp[1].startswith(lf.strip())):
        it.fail("docs/PROGRESS.md", 0, "G1.1", f"LOCK_FINGERPRINT '{lf}' != lock root {root_fp[1][:16]}")
    it.ev(f"{rel}; {len(pages)} nodes.json under docs/figma/raw/{key}")
    return it


def g1_2(ctx):
    it = Item("2", "figma_reconcile.py: 0 missing ids both directions (pages, frames, components, sets, variants, interactions)",
              "scripts/figma_reconcile.py <key> --strict")
    key = figma_keys(ctx)
    if key is None:
        it.fail("docs/figma/raw", 0, "G1.2", "no Figma file key folder")
        return it
    absorb(it, "figma_reconcile.py", ctx.run_script("figma_reconcile.py", [key, "--strict"]))
    return it


def audit_files(ctx):
    fs = ["docs/FIGMA_AUDIT.md"] + sorted(os.path.relpath(p, ctx.root) for p in glob.glob(str(ctx.p("docs/figma/analysis/*.md"))))
    return [f for f in fs if ctx.exists(f)]


def g1_3(ctx):
    it = Item("3", "No [NOT YET READ] row except metadata-only-variant rows naming an existing base-frame row",
              "gate.py G1.3: scan docs/FIGMA_AUDIT.md and docs/figma/analysis/*.md")
    files = audit_files(ctx)
    defs = {}
    for f in files:
        for i, l in enumerate(masked_lines(ctx.read(f)), 1):
            for d in line_defs(l):
                defs.setdefault(d, (f, i))
    n = 0
    for f in files:
        for i, l in enumerate(masked_lines(ctx.read(f)), 1):
            if "[NOT YET READ]" not in l:
                continue
            n += 1
            if "metadata-only-variant" not in l:
                it.fail(f, i, "NOTYETREAD", "[NOT YET READ] row without metadata-only-variant")
                continue
            own = set(line_defs(l))
            base = [x for x in re.findall(r"\b(?:SCR|FRM|CMP)-\d{4}\b", l) if x not in own and x in defs]
            if not base:
                it.fail(f, i, "G1.3", "metadata-only-variant row names no defined base-frame row")
    if not files:
        it.fail("docs/FIGMA_AUDIT.md", 0, "MISSING", "no audit or page analysis present")
    it.ev(f"{len(files)} audit files; {n} [NOT YET READ] lines")
    return it


def ledger_rows(ctx):
    t = ctx.read("docs/figma/read-ledger.md") or ""
    out = []
    for i, l in enumerate(t.split("\n"), 1):
        if re.match(r"^\|\s*\d+\s*\|", l):
            c = cells(l)
            if len(c) >= 9:
                out.append((i, c))
    return out


def g1_5(ctx):
    it = Item("5", "Ledger vs cache: every ok row has a cache file; no untagged double reads; only the designated reader read",
              "gate.py G1.5: parse docs/figma/read-ledger.md rows")
    rel = "docs/figma/read-ledger.md"
    if need(it, ctx, rel) is None:
        return it
    strat = ctx.read("docs/TOOL_STRATEGY.md") or ""
    rl = [l for l in strat.split("\n") if re.search(r"(?i)designated figma reader", l)]
    named = set(x for l in rl for x in re.findall(r"`([\w-]+)`", l))
    readers = {"orchestrator"} if (not rl or any("orchestrator" in l.lower() for l in rl)) else named
    seen = {}
    rows = [r for r in ledger_rows(ctx) if r[1][4] != "FIXTUREKEY"]
    for ln, c in rows:
        agent, tool, key, node, intent, path, result = c[2], c[3], c[4], c[5], c[6], c[7], c[8]
        if agent not in readers:
            it.fail(rel, ln, "G1.5", f"read by '{agent}', not the designated reader {sorted(readers)}")
        if result.startswith("ok"):
            fp = pathlib.Path(path) if os.path.isabs(path) else ctx.p(path)
            if not fp.exists():
                it.fail(rel, ln, "G1.5", f"ok row without cache file {path}")
        if result.startswith(("ok", "truncated", "pending")):
            k = (tool, key, node)
            if k in seen and intent not in ("lock-check", "retry", "delta-audit"):
                it.fail(rel, ln, "G1.5", f"untagged double read of {tool} {node} (first at line {seen[k]})")
            seen.setdefault(k, ln)
    it.ev(f"{rel}: {len(rows)} rows; readers {sorted(readers)}")
    return it


def g1_6(ctx):
    it = Item("6", "text-layers.csv row count > 0; text-layers.NOT-EXTRACTED.md lists only metadata-only-variant frames",
              "scripts/extract_text.py (present; run with --regenerate) + gate.py G1.6 parse")
    key = figma_keys(ctx)
    if not (SCRIPTS / "extract_text.py").exists():
        it.fail("scripts/extract_text.py", 0, "SCRIPT", "script missing")
    elif ctx.regenerate and key:
        absorb(it, "extract_text.py", ctx.run_script("extract_text.py", [key]))
    csvp = ctx.p("docs/figma/text-layers.csv")
    if not csvp.exists():
        it.fail("docs/figma/text-layers.csv", 0, "MISSING", "file absent")
    else:
        n = max(0, sum(1 for _ in csv.reader(open(csvp, encoding="utf-8", errors="replace"))) - 1)
        if n == 0:
            it.fail("docs/figma/text-layers.csv", 1, "G1.6", "no data rows")
        it.ev(f"docs/figma/text-layers.csv {n} rows")
    rel = "docs/figma/text-layers.NOT-EXTRACTED.md"
    t = need(it, ctx, rel)
    if t is not None:
        for i, l in enumerate(masked_lines(t), 1):
            if re.search(r"\b\d+:\d+\b", l) and not l.startswith("#") and "metadata-only-variant" not in l:
                it.fail(rel, i, "G1.6", "frame not extracted for a reason other than metadata-only-variant")
    return it


def g1_7(ctx):
    it = Item("7", "Every docs/figma/analysis/<page>.md passes scripts/validate_analysis.py", "scripts/validate_analysis.py <page-slug>")
    pages = sorted(glob.glob(str(ctx.p("docs/figma/analysis/*.md"))))
    if not pages:
        it.fail("docs/figma/analysis", 0, "MISSING", "no page analyses")
    if not (SCRIPTS / "validate_analysis.py").exists():
        it.fail("scripts/validate_analysis.py", 0, "SCRIPT", "script missing")
        return it
    for p in pages:
        absorb(it, "validate_analysis.py", ctx.run_script("validate_analysis.py", [pathlib.Path(p).stem]))
    it.ev(f"{len(pages)} page analyses")
    return it


# ---------------------------------------------------------------- G2
REC = "docs/RECONCILIATION.md"
REC_SECTIONS = ["Features in both", "Changed features", "Figma-only features", "Document-only features", "Contradictions",
                "Missing states", "Design-document claims", "Red-line scan summary"]
DISPOSITIONS = ["backend-only", "intentionally hidden", "forgotten in figma", "deprecated", "future", "still required"]
SRC_RE = re.compile(r"\b(FIGMA:\d+:\d+|DOC:[^\s|]+#[^\s|]+|ASSUMPTION-\d{3})")


def sec_rows(text, heading):
    s, body = section(text, re.escape(heading))
    if body is None:
        return None, []
    return s, [r for tb in tables("", start=s - 1, lines=body) for r in tb["rows"]]


def feat_rows(ctx):
    t = ctx.read("docs/PRODUCT_SPEC.md") or ""
    out = {}
    for tb in tables(t):
        for ln, c, raw in tb["rows"]:
            m = re.match(r"^\**(FEAT-\d{4})\**$", c[0]) if c else None
            if m:
                out.setdefault(m.group(1), (ln, c, raw, tb["header"]))
    return out


def g2_1(ctx):
    it = Item("1", "RECONCILIATION has every required section; Document-only dispositions from the fixed list with D-/Q-; "
              "Figma-only and in-both features have a FEAT- row with Source in PRODUCT_SPEC § 4",
              "gate.py G2.1: section headings, disposition cells, FEAT- resolution")
    t = need(it, ctx, REC)
    if t is None:
        return it
    for s in REC_SECTIONS:
        if section(t, re.escape(s))[1] is None:
            it.fail(REC, 1, "G2.1", f"section '{s}' missing")
    _, rows = sec_rows(t, "Document-only features")
    for ln, c, raw in rows:
        if not any(d in raw.lower() for d in DISPOSITIONS):
            it.fail(REC, ln, "G2.1", "document-only feature without a disposition from the fixed list")
        if not re.search(r"\b(D|Q)-\d{3}\b", raw):
            it.fail(REC, ln, "G2.1", "document-only disposition without D-nnn or Q-nnn")
    feats = feat_rows(ctx)
    for sec in ("Figma-only features", "Features in both"):
        _, rows = sec_rows(t, sec)
        for ln, c, raw in rows:
            ids = re.findall(r"\bFEAT-\d{4}\b", raw)
            if not ids:
                it.fail(REC, ln, "G2.1", f"{sec} row cites no FEAT- id")
            for f in ids:
                if f not in feats:
                    it.fail(REC, ln, "G2.1", f"{f} not defined in docs/PRODUCT_SPEC.md")
                elif not SRC_RE.search(feats[f][2].replace(f, "")):
                    it.fail("docs/PRODUCT_SPEC.md", feats[f][0], "NOSOURCE", f"{f} row has no Source")
    it.ev(f"{REC}; PRODUCT_SPEC {len(feats)} FEAT- rows")
    return it


def g2_2(ctx):
    it = Item("2", "Contradictions >=1 row, or a NONE FOUND row with [EV:] to the comparison log", "gate.py G2.2")
    t = need(it, ctx, REC)
    if t is None:
        return it
    s, rows = sec_rows(t, "Contradictions")
    if s is None or not rows:
        it.fail(REC, s or 0, "G2.2", "Contradictions section has no rows")
    for ln, c, raw in rows:
        if "NONE FOUND" in raw:
            evs = EV_RE.findall(raw)
            if not evs or not all(ctx.exists(e) for e in evs):
                it.fail(REC, ln, "G2.2", "NONE FOUND without an existing [EV:] comparison log")
    it.ev(f"{REC} Contradictions: {len(rows)} rows")
    return it


def g2_3(ctx):
    it = Item("3", "Every FIGMA-GAP- id appears in Missing states", "gate.py G2.3: FIGMA-GAP ids in docs/figma/*.md vs the section")
    t = need(it, ctx, REC)
    if t is None:
        return it
    gaps = {}
    for f in ["docs/figma/FIGMA_STATE_REPORT.md"] + sorted(os.path.relpath(p, ctx.root) for p in glob.glob(str(ctx.p("docs/figma/*.md")))):
        for i, l in enumerate((ctx.read(f) or "").split("\n"), 1):
            for g in re.findall(r"\bFIGMA-GAP-\d{3}\b", l):
                gaps.setdefault(g, (f, i))
    s, body = section(t, "Missing states")
    txt = "\n".join(body or [])
    for g, (f, i) in sorted(gaps.items()):
        if g not in txt:
            it.fail(f, i, "G2.3", f"{g} not in {REC} Missing states")
    it.ev(f"{len(gaps)} FIGMA-GAP ids")
    return it


def g2_4(ctx):
    it = Item("4", "copy-scan.md rows scanned = text-layers.csv rows; every hit has a node id",
              "scripts/copy_scan.py (present; run with --regenerate) + gate.py G2.4 parse")
    if not (SCRIPTS / "copy_scan.py").exists():
        it.fail("scripts/copy_scan.py", 0, "SCRIPT", "script missing")
    elif ctx.regenerate:
        absorb(it, "copy_scan.py", ctx.run_script("copy_scan.py", ["--input", "docs/figma/text-layers.csv"]), ok_codes=(0, 1))
    rel = "docs/figma/copy-scan.md"
    t = need(it, ctx, rel)
    csvp = ctx.p("docs/figma/text-layers.csv")
    n = max(0, sum(1 for _ in csv.reader(open(csvp, encoding="utf-8", errors="replace"))) - 1) if csvp.exists() else None
    if n is None:
        it.fail("docs/figma/text-layers.csv", 0, "MISSING", "file absent")
    if t is None:
        return it
    m = re.search(r"(?i)rows scanned\D{0,20}(\d+)", t)
    if not m:
        it.fail(rel, 1, "G2.4", "no 'rows scanned' count")
    elif n is not None and int(m.group(1)) != n:
        it.fail(rel, 1, "G2.4", f"rows scanned {m.group(1)} != text-layers.csv rows {n}")
    hits = 0
    for tb in tables(t):
        if col(tb["header"], "category") is None:
            continue
        nc = col(tb["header"], "node")
        for ln, c, raw in tb["rows"]:
            hits += 1
            if not re.search(r"\b\d+:\d+\b", cell(c, nc) if nc is not None else raw):
                it.fail(rel, ln, "G2.4", "hit without node id")
    it.ev(f"{rel}: {hits} hit rows; text-layers rows {n}")
    return it


def g2_5(ctx):
    it = Item("5", "CHANGELOG_FROM_ORIGINAL_SPEC has >=1 row per Changed / Figma-only / Document-only feature",
              "gate.py G2.5: each feature's FEAT- id (else first cell) found in docs/CHANGELOG_FROM_ORIGINAL_SPEC.md")
    t = need(it, ctx, REC)
    ch = need(it, ctx, "docs/CHANGELOG_FROM_ORIGINAL_SPEC.md")
    if t is None or ch is None:
        return it
    n = 0
    for sec in ("Changed features", "Figma-only features", "Document-only features"):
        _, rows = sec_rows(t, sec)
        for ln, c, raw in rows:
            n += 1
            ids = re.findall(r"\bFEAT-\d{4}\b", raw)
            key = ids[0] if ids else strip_md(c[0])
            if key and key not in ch:
                it.fail(REC, ln, "G2.5", f"'{key[:60]}' ({sec}) has no CHANGELOG row")
    it.ev(f"{n} feature rows checked")
    return it


def g2_6(ctx):
    it = Item("6", "design_doc_xref.py output attached; every [DESIGN-DOC-ONLY] item listed in RECONCILIATION",
              "scripts/design_doc_xref.py + gate.py G2.6 (unfound items vs Design-document claims section)")
    res = ctx.run_script("design_doc_xref.py", [])
    if not absorb(it, "design_doc_xref.py", res):
        return it
    t = need(it, ctx, REC)
    if t is None:
        return it
    s, body = section(t, "Design-document claims")
    if body is None:
        it.fail(REC, 0, "G2.6", "no Design-document claims section")
        return it
    btxt = "\n".join(body)
    unfound = 0
    for tb in tables(res[1]):
        for ln, c, raw in tb["rows"]:
            if any(re.match(r"^(no|not found|unfound|false|missing)$", strip_md(x), re.I) for x in c[1:]):
                unfound += 1
                name = strip_md(c[0])
                if not any(name in l and "[DESIGN-DOC-ONLY]" in l for l in body):
                    it.fail(REC, s, "G2.6", f"unfound design-doc item '{name[:60]}' not listed with [DESIGN-DOC-ONLY]")
    it.ev(f"design_doc_xref unfound items {unfound}; section lines {len(body)}; DESIGN-DOC-ONLY tags {btxt.count('[DESIGN-DOC-ONLY]')}")
    return it


# ---------------------------------------------------------------- G3
def g3_1(ctx):
    it = Item("1", "Every FEAT- row has a Source; each acceptance criterion cites SCR-/INT-, DOC: or ASSUMPTION- and has a "
              "TEST- in ENGINE_TEST_PLAN or N/A (UI test …)/N/A (manual: FVC row …)",
              "gate.py G3.1: PRODUCT_SPEC FEAT- rows, Acceptance column or Acceptance-criteria section lines")
    if need(it, ctx, "docs/PRODUCT_SPEC.md") is None:
        return it
    t = ctx.read("docs/PRODUCT_SPEC.md")
    tests = set(x for x in re.findall(r"\bTEST-\d{4}\b", "\n".join(
        l for l in masked_lines(ctx.read("docs/ENGINE_TEST_PLAN.md") or "") if line_defs(l))))
    feats = feat_rows(ctx)
    if not feats:
        it.fail("docs/PRODUCT_SPEC.md", 0, "G3.1", "no FEAT- rows")
    s, acbody = section(t, r"acceptance criteria")
    for f, (ln, c, raw, hdr) in sorted(feats.items()):
        sc = col(hdr, "source")
        if not SRC_RE.search(cell(c, sc) if sc is not None else raw.replace(f, "")):
            it.fail("docs/PRODUCT_SPEC.md", ln, "NOSOURCE", f"{f} has no Source in FIGMA:/DOC:/ASSUMPTION- form")
        ac = col(hdr, "acceptance")
        crit = []
        if ac is not None:
            crit = [(ln, x) for x in re.split(r"<br\s*/?>|;|•", cell(c, ac)) if x.strip()]
        elif acbody:
            crit = [(s + i, l) for i, l in enumerate(acbody) if f in l and l.strip()]
        if not crit:
            it.fail("docs/PRODUCT_SPEC.md", ln, "G3.1", f"{f}: no acceptance criteria found")
        for cl, x in crit:
            if not re.search(r"\b(SCR|INT)-\d{4}\b|DOC:\S+|ASSUMPTION-\d{3}", x):
                it.fail("docs/PRODUCT_SPEC.md", cl, "G3.1", f"{f}: criterion cites no SCR-/INT-, DOC: or ASSUMPTION-")
            tids = re.findall(r"\bTEST-\d{4}\b", x)
            if "N/A (UI test: TESTING_STRATEGY, Phase 14)" in x or "N/A (manual: FVC row" in x:
                continue
            if not tids:
                it.fail("docs/PRODUCT_SPEC.md", cl, "G3.1", f"{f}: criterion without TEST- or N/A (UI test/manual)")
            for tid in tids:
                if tid not in tests:
                    it.fail("docs/PRODUCT_SPEC.md", cl, "G3.1", f"{f}: {tid} not defined in docs/ENGINE_TEST_PLAN.md")
    it.ev(f"docs/PRODUCT_SPEC.md {len(feats)} FEAT- rows; ENGINE_TEST_PLAN {len(tests)} TEST- definitions")
    return it


DATA_LABELS = ["purpose", "fields", "relationships", "ownership", "persistence", "sensitivity", "source",
               "residency", "internalonly", "source of truth", "synchroni", "validation", "deletion", "migration"]


def g3_2(ctx):
    it = Item("2", "Every SCR- has a UI- row; every UI- row names its DATA- dependencies; every DATA- entity has every Phase 7 "
              "column, pharmacology-style fields internalOnly: yes, 8.1.3 fields residency device-only",
              "gate.py G3.2: FIGMA_AUDIT, FIGMA_IMPLEMENTATION_MAP, DATA_MODEL")
    audit = need(it, ctx, "docs/FIGMA_AUDIT.md") or ""
    imap = need(it, ctx, "docs/FIGMA_IMPLEMENTATION_MAP.md") or ""
    dm = need(it, ctx, "docs/DATA_MODEL.md")
    uirows = [(ln, c, raw, tb["header"]) for tb in tables(imap) for ln, c, raw in tb["rows"]
              if c and re.match(r"^\**UI-\d{4}\**$", c[0])]
    uitxt = "\n".join(r[2] for r in uirows)
    for i, l in enumerate(masked_lines(audit), 1):
        for d in line_defs(l):
            if d.startswith("SCR-"):
                node = re.search(r"\b\d+:\d+\b", l)
                if d not in uitxt and not (node and re.search(r"(?<![\d:])" + re.escape(node.group(0)) + r"(?![\d:])", uitxt)):
                    it.fail("docs/FIGMA_AUDIT.md", i, "G3.2", f"{d} has no UI- row")
    for ln, c, raw, hdr in uirows:
        dc = col(hdr, "DATA")
        v = cell(c, dc) if dc is not None else raw
        if (dc is not None and is_empty(v)) or (not re.search(r"\bDATA-\d{4}\b", v) and not re.search(r"N/A \(", v)):
            it.fail("docs/FIGMA_IMPLEMENTATION_MAP.md", ln, "G3.2", f"{strip_md(c[0])} names no DATA- dependency")
    if dm is None:
        return it
    lines = masked_lines(dm)
    ents = 0
    for tb in tables(dm):
        for ln, c, raw in tb["rows"]:
            if c and re.match(r"^\**DATA-\d{4}\**$", c[0]):
                ents += 1
                for lab in DATA_LABELS:
                    ci = col(tb["header"], lab)
                    if ci is None or is_empty(cell(c, ci)):
                        it.fail("docs/DATA_MODEL.md", ln, "G3.2", f"{strip_md(c[0])}: Phase 7 column '{lab}' missing or empty")
    for i, l in enumerate(lines):
        m = re.match(r"^(#{2,5})\s+\**(DATA-\d{4})", l)
        if not m:
            continue
        ents += 1
        block = []
        for j in range(i + 1, len(lines)):
            m2 = re.match(r"^(#{1,6})\s", lines[j])
            if m2 and len(m2.group(1)) <= len(m.group(1)):
                break
            block.append(lines[j])
        btxt = "\n".join(block).lower()
        for lab in DATA_LABELS:
            mm = re.search(re.escape(lab) + r"[^:|\n]*[:|]\s*([^\n|]*)", btxt)
            if not mm or is_empty(mm.group(1)) and lab not in ("fields", "internalonly", "residency", "source"):
                it.fail("docs/DATA_MODEL.md", i + 1, "G3.2", f"{m.group(2)}: Phase 7 attribute '{lab}' missing or empty")
    if ents == 0:
        it.fail("docs/DATA_MODEL.md", 0, "G3.2", "no DATA- entities")
    for i, l in enumerate(lines, 1):
        fieldish = re.search(r"\w+\s*:\s*[A-Z\[]\w*", l) or l.lstrip().startswith(("|", "- "))
        if not fieldish:
            continue
        if PHARMA.search(l) and not re.search(r"internalOnly\W{1,5}(yes|true)", l, re.I) and not line_defs(l) \
                and re.search(r"\w+\s*:\s*\w+", l):
            it.fail("docs/DATA_MODEL.md", i, "G3.2", "pharmacology-style field not marked internalOnly: yes")
        r = re.search(r"residency\W{1,5}([a-z-]+)", l, re.I)
        if r and r.group(1).lower() != "device-only" and SENSITIVE_813.search(l):
            it.fail("docs/DATA_MODEL.md", i, "G3.2", f"8.1.3-class field with residency {r.group(1)} (must be device-only)")
    it.ev(f"UI- rows {len(uirows)}; DATA- entities {ents}")
    return it


def g3_3(ctx):
    it = Item("3", "ENG- invariants INV-RL1, INV-RL2, INV-RL6, INV-RL7, INV-RL8 exist and each has a TEST-",
              "gate.py G3.3: ENGINE_SPEC definitions; TEST- on a line naming the invariant")
    es = need(it, ctx, "docs/ENGINE_SPEC.md")
    tp = ctx.read("docs/ENGINE_TEST_PLAN.md") or ""
    if es is None:
        return it
    for inv in ("INV-RL1", "INV-RL2", "INV-RL6", "INV-RL7", "INV-RL8"):
        pat = re.compile(r"(?<![\w-])" + inv + r"(?!\d)")
        defined = any(pat.search(l) and (l.lstrip().startswith("#") or "**" + inv in l or re.match(r"^\|\s*\**" + inv, l))
                      for l in masked_lines(es))
        if not defined:
            it.fail("docs/ENGINE_SPEC.md", 0, "G3.3", f"{inv} not defined (heading, bold or first table cell)")
        if not any(pat.search(l) and re.search(r"\bTEST-\d{4}\b", l) for l in (tp + "\n" + es).split("\n")):
            it.fail("docs/ENGINE_TEST_PLAN.md", 0, "G3.3", f"{inv} has no TEST- on a line naming it")
    it.ev("docs/ENGINE_SPEC.md, docs/ENGINE_TEST_PLAN.md")
    return it


def g3_4(ctx):
    it = Item("4", "Every IOS- row has Framework, Permission (or none), Minimum iOS, watchOS (or N/A (iPhone-only)), Simulator, "
              "Fallback, `verified 2026-`, and [EV: docs/evidence/sources/IOS-nnnn.md] whose excerpt has the version",
              "gate.py G3.4: APPLE_PLATFORM_PLAN IOS- rows and evidence excerpts")
    rel = "docs/APPLE_PLATFORM_PLAN.md"
    t = need(it, ctx, rel)
    if t is None:
        return it
    n = 0
    for tb in tables(t):
        h = tb["header"]
        cols = {"framework": col(h, "framework"), "permission": col(h, "permission"), "minimum ios": col(h, "minimum ios", "min ios"),
                "watchos": col(h, "watchos"), "simulator": col(h, "simulator"), "fallback": col(h, "fallback")}
        for ln, c, raw in tb["rows"]:
            m = re.match(r"^\**(IOS-\d{4})\**$", c[0]) if c else None
            if not m:
                continue
            n += 1
            ident = m.group(1)
            for k, ci in cols.items():
                if ci is None or is_empty(cell(c, ci)) and not (k == "watchos" and "iphone-only" in cell(c, ci).lower()):
                    it.fail(rel, ln, "G3.4", f"{ident}: {k} column missing or empty")
            if not re.search(r"verified 2026-\d{2}-\d{2}", raw):
                it.fail(rel, ln, "G3.4", f"{ident}: no 'verified 2026-MM-DD'")
            evp = f"docs/evidence/sources/{ident}.md"
            if evp not in EV_RE.findall(raw):
                it.fail(rel, ln, "G3.4", f"{ident}: no [EV: {evp}]")
                continue
            ex = ctx.read(evp)
            if ex is None:
                it.fail(rel, ln, "G3.4", f"{ident}: evidence file missing")
                continue
            ver = re.search(r"\d+(?:\.\d+)?", cell(c, cols["minimum ios"]))
            excerpt = ex.split("## Excerpt", 1)[-1]
            if ver and ver.group(0) not in excerpt and "[UNVERIFIED]" not in raw:
                it.fail(rel, ln, "G3.4", f"{ident}: excerpt lacks claimed version {ver.group(0)} and row not [UNVERIFIED]")
    if n == 0:
        it.fail(rel, 0, "G3.4", "no IOS- rows")
    it.ev(f"{rel}: {n} IOS- rows")
    return it


def g_script(ctx, label, check, name, args=()):
    it = Item(label, check, f"scripts/{name} {' '.join(args)}".strip())
    absorb(it, name, ctx.run_script(name, list(args)))
    return it


def g3_6(ctx):
    it = Item("6", "Every ARCHITECTURE dependency has a 'boring alternative it beat' paragraph and `CHALLENGED: accepted|rejected`",
              "gate.py G3.6: Dependencies section entries")
    rel = "docs/ARCHITECTURE.md"
    t = need(it, ctx, rel)
    if t is None:
        return it
    s, body = section(t, r"dependenc")
    if body is None:
        it.fail(rel, 0, "G3.6", "no Dependencies section")
        return it
    units, cur = [], None
    for i, l in enumerate(body):
        if re.match(r"^#{2,6}\s", l):
            cur = [s + i, [l]]
            units.append(cur)
        elif cur is not None:
            cur[1].append(l)
    if not units:
        units = [[ln, [raw]] for tb in tables("", start=s - 1, lines=body) for ln, c, raw in tb["rows"]]
    if not units:
        it.fail(rel, s, "G3.6", "Dependencies section lists no dependency")
    for ln, ls in units:
        txt = "\n".join(ls)
        if not re.search(r"boring alternative", txt, re.I):
            it.fail(rel, ln, "G3.6", "dependency without a 'boring alternative it beat' paragraph")
        if not re.search(r"CHALLENGED:\s*(accepted|rejected)", txt):
            it.fail(rel, ln, "G3.6", "dependency without 'CHALLENGED: accepted|rejected'")
    it.ev(f"{rel}: {len(units)} dependency entries")
    return it


def g3_7(ctx):
    it = Item("7", "DESIGN_SYSTEM tokens each cite a cached variable or design-context node; differences from handoff listed",
              "gate.py G3.7: token tables need a node id or docs/figma/raw path; handoff section present")
    rel = "docs/DESIGN_SYSTEM.md"
    t = need(it, ctx, rel)
    if t is None:
        return it
    n = 0
    for tb in tables(t):
        if col(tb["header"], "token") is None:
            continue
        for ln, c, raw in tb["rows"]:
            n += 1
            if not re.search(r"\b\d+:\d+\b|docs/figma/raw/", raw):
                it.fail(rel, ln, "G3.7", f"token '{strip_md(c[0])[:50]}' cites no cached node or variable")
    if n == 0:
        it.fail(rel, 0, "G3.7", "no token table rows")
    if not re.search(r"(?mi)^#{1,6}.*handoff", t):
        it.fail(rel, 0, "G3.7", "no section listing differences from docs/design/handoff.md (or its substitute)")
    it.ev(f"{rel}: {n} token rows")
    return it


LEGAL_COLS = ["id", "item", "class", "confidence", "source", "verified", "applies", "enforced", "test"]


def g3_9(ctx):
    it = Item("9", "Every LEGAL- row has all Phase 11.2 columns filled; class and confidence valid; Enforced-in ids resolve",
              "gate.py G3.9: LEGAL_PRIVACY_SAFETY tables; id definitions across deliverables")
    rel = "docs/LEGAL_PRIVACY_SAFETY.md"
    t = need(it, ctx, rel)
    if t is None:
        return it
    defs = ctx.defs()
    n = 0
    for tb in tables(t):
        h = tb["header"]
        for ln, c, raw in tb["rows"]:
            m = re.match(r"^\**(LEGAL-(?:\d{4}|DH-\d{2}|SAFE-\d{2}))\**$", c[0]) if c else None
            if not m:
                continue
            n += 1
            ident = m.group(1)
            idx = {k: col(h, k) for k in LEGAL_COLS}
            for k, ci in idx.items():
                if ci is None or is_empty(cell(c, ci)):
                    it.fail(rel, ln, "G3.9", f"{ident}: column '{k}' missing or empty")
            cl = strip_md(cell(c, idx["class"])).upper()
            if cl and cl not in ("LEGAL", "PLATFORM", "PRACTICE", "DESIGN", "NEEDS-LAWYER"):
                it.fail(rel, ln, "G3.9", f"{ident}: class '{cl}' not in the 11.2 scheme")
            cf = strip_md(cell(c, idx["confidence"])).split(" ")[0].capitalize()
            if cf and cf not in ("High", "Medium", "Low"):
                it.fail(rel, ln, "G3.9", f"{ident}: confidence '{cf}' not High/Medium/Low")
            if not re.search(r"\d{4}-\d{2}-\d{2}", cell(c, idx["verified"])):
                it.fail(rel, ln, "G3.9", f"{ident}: verified date missing")
            enf = ID_ANY.findall(cell(c, idx["enforced"]))
            if not enf:
                it.fail(rel, ln, "G3.9", f"{ident}: Enforced in names no id")
            for e in enf:
                if e not in defs:
                    it.fail(rel, ln, "G3.9", f"{ident}: Enforced-in id {e} not defined in any deliverable")
    if n == 0:
        it.fail(rel, 0, "G3.9", "no LEGAL- rows")
    it.ev(f"{rel}: {n} LEGAL- rows")
    return it


# ---------------------------------------------------------------- G4
def g4_4(ctx):
    it = Item("4", "trace.py: 0 orphan TEST-, 0 FEAT- without task, 0 task without TEST-/N/A, no empty cells; "
              "no 'N/A (UI test: TESTING_STRATEGY, Phase 14)' left in PRODUCT_SPEC", "scripts/trace.py + gate.py G4.4 grep")
    absorb(it, "trace.py", ctx.run_script("trace.py", []))
    t = ctx.read("docs/PRODUCT_SPEC.md")
    if t is None:
        it.fail("docs/PRODUCT_SPEC.md", 0, "MISSING", "file absent")
    else:
        for i, l in enumerate(t.split("\n"), 1):
            if "N/A (UI test: TESTING_STRATEGY, Phase 14)" in l:
                it.fail("docs/PRODUCT_SPEC.md", i, "G4.4", "interim 'N/A (UI test: TESTING_STRATEGY, Phase 14)' remains")
    return it


def g4_5(ctx):
    it = Item("5", "CLAUDE.md, docs/PROGRESS.md and docs/DEVESH_BUILD_GUIDE.md exist, end with the marker and pass the validator",
              "scripts/validate_docs.py <the three files>")
    fs = ["CLAUDE.md", "docs/PROGRESS.md", "docs/DEVESH_BUILD_GUIDE.md"]
    for f in fs:
        t = ctx.read(f)
        if t is None:
            it.fail(f, 0, "MISSING", "file absent")
        elif "<!-- END OF FILE -->" not in t[-400:]:
            it.fail(f, len(t.split("\n")), "END", "missing <!-- END OF FILE -->")
    absorb(it, "validate_docs.py", ctx.run_script("validate_docs.py", [f for f in fs if ctx.exists(f)]))
    return it


def g4_6(ctx):
    it = Item("6", "Every numbered step in DEVESH_BUILD_GUIDE has a 'what you should see' line", "gate.py G4.6: numbered-step blocks")
    rel = "docs/DEVESH_BUILD_GUIDE.md"
    t = need(it, ctx, rel)
    if t is None:
        return it
    ls = masked_lines(t)
    starts = [i for i, l in enumerate(ls) if re.match(r"^\s{0,3}\d+\.\s", l)]
    for k, i in enumerate(starts):
        end = starts[k + 1] if k + 1 < len(starts) else len(ls)
        for j in range(i + 1, end):
            if re.match(r"^#{1,6}\s", ls[j]):
                end = j
                break
        if not re.search(r"what you should see", "\n".join(ls[i:end]), re.I):
            it.fail(rel, i + 1, "G4.6", "numbered step without a 'what you should see' line")
    if not starts:
        it.fail(rel, 0, "G4.6", "no numbered steps")
    it.ev(f"{rel}: {len(starts)} numbered steps")
    return it


def g4_7(ctx):
    it = Item("7", "Every verification verb has [EV:] (validator EV and EVLOG rules)", "scripts/validate_docs.py --manifest, EV/EVLOG lines")
    res = ctx.run_script("validate_docs.py", ["--manifest"])
    if res is None:
        it.fail("scripts/validate_docs.py", 0, "SCRIPT", "script missing")
        return it
    n = 0
    for l in res[1].splitlines():
        m = LINE_RE.match(l)
        if m and m.group("r") in ("EV", "EVLOG"):
            n += 1
            it.fail(m.group("f"), m.group("l"), m.group("r"), m.group("m"))
    it.ev(f"validate_docs --manifest: {n} EV/EVLOG failures")
    return it


def g4_8(ctx):
    it = Item("8", "Spec-drift report attached; every SPEC_CHECKLIST.md requirement ticked or RESIDUAL-",
              "gate.py G4.8: SPEC_CHECKLIST.md checkboxes; docs/evidence/**/*drift*report*")
    rel = "SPEC_CHECKLIST.md"
    t = need(it, ctx, rel)
    reports = [p for p in glob.glob(str(ctx.p("docs/evidence/**/*drift*report*")), recursive=True)]
    if not reports:
        it.fail("docs/evidence", 0, "G4.8", "no spec-drift report (docs/evidence/**/*drift*report*)")
    if t is None:
        return it
    n = open_ = 0
    for i, l in enumerate(t.split("\n"), 1):
        m = re.match(r"^\s*-\s*\[( |x|X)\]", l)
        if not m:
            continue
        n += 1
        if m.group(1) == " " and not re.search(r"\bRESIDUAL-\d{3}\b", l):
            open_ += 1
            it.fail(rel, i, "G4.8", "requirement neither ticked nor RESIDUAL-")
    if n == 0:
        it.fail(rel, 0, "G4.8", "no checklist items")
    it.ev(f"{rel}: {n} items, {open_} open; drift reports {len(reports)}")
    return it


def g4_9(ctx):
    it = Item("9", "CLAUDE.md keeps the bootstrap block verbatim and includes the red lines and the NEVER list",
              "gate.py G4.9: read-only `git show <Phase 0 commit>:CLAUDE.md` prefix comparison; RL-1..RL-9 and NEVER present")
    t = need(it, ctx, "CLAUDE.md")
    if t is None:
        return it
    code, out, err = ctx.git("log", "--format=%H %s", "--", "CLAUDE.md")
    commits = [l.split(" ", 1) for l in out.splitlines() if l.strip()] if code == 0 else []
    ph0 = [h for h, s in commits if re.match(r"^Phase 0(:|\s|$)", s)]
    ref = ph0[0] if ph0 else (commits[-1][0] if commits else None)
    if ref is None:
        it.fail("CLAUDE.md", 0, "G4.9", "no committed bootstrap CLAUDE.md to compare with")
    else:
        c2, boot, e2 = ctx.git("show", f"{ref}:CLAUDE.md")
        boot = boot.replace("<!-- END OF FILE -->", "").rstrip()
        if c2 != 0 or not boot:
            it.fail("CLAUDE.md", 0, "G4.9", f"git show {ref[:10]}:CLAUDE.md failed")
        elif not t.startswith(boot):
            bl, cl = boot.split("\n"), t.split("\n")
            k = next((i for i in range(len(bl)) if i >= len(cl) or bl[i] != cl[i]), 0)
            it.fail("CLAUDE.md", k + 1, "G4.9", f"bootstrap block not verbatim (differs from {ref[:10]}:CLAUDE.md line {k + 1})")
        it.ev(f"bootstrap reference {ref[:10]} ({'Phase 0 commit' if ph0 else 'first commit of CLAUDE.md'})")
    for n in range(1, 10):
        if not re.search(r"\bRL-%d\b" % n, t):
            it.fail("CLAUDE.md", 0, "G4.9", f"RL-{n} missing")
    if not re.search(r"(?m)^#{1,6}.*NEVER", t):
        it.fail("CLAUDE.md", 0, "G4.9", "no NEVER list heading")
    return it


def g4_11(ctx):
    it = Item("11", "au_spelling.py: 0 failures in UI strings (documents warn; string files --strict)",
              "scripts/au_spelling.py <manifest .md>; --strict on /poc string files")
    docs = [p for ln, p, c in manifest_rows(ctx) if p.endswith(".md") and ctx.exists(p)]
    absorb(it, "au_spelling.py", ctx.run_script("au_spelling.py", docs))
    ui = [os.path.relpath(p, ctx.root) for pat in ("poc/**/*.xcstrings", "poc/**/*.strings")
          for p in glob.glob(str(ctx.p(pat)), recursive=True)]
    if ui and (SCRIPTS / "au_spelling.py").exists():
        absorb(it, "au_spelling.py", ctx.run_script("au_spelling.py", ui + ["--strict"]))
    it.ev(f"{len(docs)} documents; {len(ui)} UI string files")
    return it


def g4_12(ctx):
    it = Item("12", "Every REL- Blocks row names an evidence path pattern; every Phase 11.7 Q-L item is in OPEN_QUESTIONS",
              "gate.py G4.12: RELEASE_CHECKLIST Blocks/evidence cells; Q-L ids from prompts/01 § 11.7")
    rel = "docs/RELEASE_CHECKLIST.md"
    t = need(it, ctx, rel)
    if t is not None:
        n = 0
        for tb in tables(t):
            bc, ec = col(tb["header"], "block"), col(tb["header"], "evidence")
            for ln, c, raw in tb["rows"]:
                if not (c and re.match(r"^\**REL-\d{3}", c[0])):
                    continue
                n += 1
                if bc is None:
                    it.fail(rel, ln, "G4.12", "no Blocks column")
                elif re.match(r"^\W*yes", cell(c, bc), re.I) and "docs/evidence/release/" not in cell(c, ec):
                    it.fail(rel, ln, "G4.12", f"{strip_md(c[0])} blocks release but names no docs/evidence/release/ path")
        if n == 0:
            it.fail(rel, 0, "G4.12", "no REL- rows")
        it.ev(f"{rel}: {n} REL- rows")
    pr = ctx.read("prompts/01_MASTER_PLANNING_PROMPT.md") or ""
    s, body = section(pr, r"^11\.7")
    qls = sorted(set(re.findall(r"\bQ-L(\d+)\b", "\n".join(body or []))), key=int) or [str(i) for i in range(1, 19)]
    oq = need(it, ctx, "docs/OPEN_QUESTIONS.md")
    if oq is not None:
        for q in qls:
            if not re.search(r"\bQ-L0*%s\b" % q, oq):
                it.fail("docs/OPEN_QUESTIONS.md", 0, "G4.12", f"Q-L{q} (Phase 11.7) not in OPEN_QUESTIONS")
    it.ev(f"{len(qls)} Q-L items")
    return it


# ---------------------------------------------------------------- G5
def g5_1(ctx):
    it = Item("1", "COMPLETENESS_AUDIT items 1-12 each PASS, or FAIL converted to RESIDUAL- with reason, file#section, owner; "
              "no residual of a hard-fail class", "gate.py G5.1: COMPLETENESS_AUDIT results; RESIDUAL- rows there or in docs/gates/GATE-5.md")
    rel = "docs/COMPLETENESS_AUDIT.md"
    t = need(it, ctx, rel)
    if t is None:
        return it
    results = {}
    for tb in tables(t):
        rc = col(tb["header"], "result")
        if rc is None:
            continue
        for ln, c, raw in tb["rows"]:
            m = re.match(r"^\**(\d{1,2})\b", c[0]) if c else None
            if m:
                r = re.search(r"PASS|FAIL", cell(c, rc))
                results.setdefault(int(m.group(1)), (ln, r.group(0) if r else "", raw))
    ls = masked_lines(t)
    for i, l in enumerate(ls):
        m = re.match(r"^#{2,4}\s*(?:Item\s*)?(\d{1,2})[.\s:)]", l)
        if m and int(m.group(1)) not in results:
            for j in range(i + 1, len(ls)):
                if re.match(r"^#{1,4}\s", ls[j]):
                    break
                r = re.search(r"Result:\s*\**(PASS|FAIL)", ls[j])
                if r:
                    results[int(m.group(1))] = (j + 1, r.group(1), "\n".join(ls[i:j + 1]))
                    break
    res_rows = {}
    for f in (rel, "docs/gates/GATE-5.md"):
        for tb in tables(ctx.read(f) or ""):
            for ln, c, raw in tb["rows"]:
                m = re.match(r"^\**(RESIDUAL-\d{3})\**$", c[0]) if c else None
                if m:
                    res_rows.setdefault(m.group(1), (f, ln, c, raw))
    for n in range(1, 13):
        if n not in results:
            it.fail(rel, 0, "G5.1", f"item {n}: no PASS/FAIL result found")
            continue
        ln, r, raw = results[n]
        if r == "PASS":
            continue
        if r != "FAIL":
            it.fail(rel, ln, "G5.1", f"item {n}: result is neither PASS nor FAIL")
            continue
        rids = re.findall(r"\bRESIDUAL-\d{3}\b", raw)
        if not rids:
            it.fail(rel, ln, "G5.1", f"item {n} FAIL without a RESIDUAL- id")
        for rid in rids:
            if rid not in res_rows:
                it.fail(rel, ln, "G5.1", f"{rid} has no residual row")
                continue
            f, rl, c, rraw = res_rows[rid]
            if any(is_empty(x) for x in c):
                it.fail(f, rl, "G5.1", f"{rid}: empty cell")
            if not re.search(r"\b(build-phase|Devesh)\b", rraw):
                it.fail(f, rl, "G5.1", f"{rid}: owner not build-phase or Devesh")
            if not re.search(r"[\w./-]+\.md#\S+", rraw):
                it.fail(f, rl, "G5.1", f"{rid}: no file#section")
            if HARD_TEXT.search(rraw):
                it.fail(f, rl, "HARDFAIL", f"{rid} belongs to a hard-fail class (E2 applies, not a residual)")
    it.ev(f"{rel}: {len(results)} item results; {len(res_rows)} residual rows")
    return it


# ---------------------------------------------------------------- registry and report
def build(ctx):
    g = ctx.gate
    if g == 0:
        items = [lambda: g0_1(ctx), lambda: g0_2(ctx), lambda: g0_3(ctx), lambda: g0_4(ctx),
                 lambda: g_validate_manifest(ctx, "5"), lambda: g0_6(ctx), lambda: g0_7(ctx), lambda: g0_8(ctx)]
    elif g == 1:
        items = [lambda: g1_1(ctx), lambda: g1_2(ctx), lambda: g1_3(ctx),
                 lambda: g_script(ctx, "4", "scripts/validate_docs.py exits 0 (ids conform, ranges respected)", "validate_docs.py", ["--manifest"]),
                 lambda: g1_5(ctx), lambda: g1_6(ctx), lambda: g1_7(ctx)]
    elif g == 2:
        items = [lambda: g2_1(ctx), lambda: g2_2(ctx), lambda: g2_3(ctx), lambda: g2_4(ctx), lambda: g2_5(ctx), lambda: g2_6(ctx)]
    elif g == 3:
        items = [lambda: g3_1(ctx), lambda: g3_2(ctx), lambda: g3_3(ctx), lambda: g3_4(ctx),
                 lambda: g_script(ctx, "5", "scripts/check_facts.py 0 mismatches", "check_facts.py"),
                 lambda: g3_6(ctx), lambda: g3_7(ctx),
                 lambda: g_script(ctx, "8", "scripts/check_names.py 0 collisions", "check_names.py"),
                 lambda: g3_9(ctx)]
    elif g == 4:
        items = [lambda: g_validate_manifest(ctx, "1"),
                 lambda: g_script(ctx, "2", "scripts/check_facts.py 0 mismatches", "check_facts.py"),
                 lambda: g_script(ctx, "3", "scripts/check_tasks.py: graph acyclic; all Phase 17 columns; no time estimates", "check_tasks.py"),
                 lambda: g4_4(ctx), lambda: g4_5(ctx), lambda: g4_6(ctx), lambda: g4_7(ctx), lambda: g4_8(ctx), lambda: g4_9(ctx),
                 lambda: g_script(ctx, "10", "scripts/check_scope.sh passes", "check_scope.sh"),
                 lambda: g4_11(ctx), lambda: g4_12(ctx)]
    else:
        items = [lambda: g5_1(ctx)]
    labels = [str(i + 1) for i in range(len(items))]
    reg = list(zip(labels, items)) + [("C", lambda: item_counters(ctx))]
    if g >= 3:
        reg.append(("REDLINE", lambda: item_redline(ctx)))
    return reg


def esc(s):
    return s.replace("|", "/").replace("\n", " ")


def main():
    ap = argparse.ArgumentParser(prog="gate.py", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter,
                                 usage=argparse.SUPPRESS, add_help=True)
    ap.add_argument("gate", help="G0..G5")
    ap.add_argument("--loop", type=int, default=1)
    ap.add_argument("--root", default=str(SCRIPTS.parent))
    ap.add_argument("--items", default="")
    ap.add_argument("--file-key", default=None)
    ap.add_argument("--regenerate", action="store_true")
    a = ap.parse_args()
    m = re.match(r"^G([0-5])$", a.gate.upper())
    if not m:
        print(f"gate.py: gate must be G0..G5, got '{a.gate}'", file=sys.stderr)
        sys.exit(2)
    root = pathlib.Path(a.root).resolve()
    if not root.is_dir():
        print(f"gate.py: root {root} is not a directory", file=sys.stderr)
        sys.exit(2)
    ctx = Ctx(root, int(m.group(1)), a.file_key, a.regenerate)
    MANIFEST_PATHS.update(p for ln, p, c in manifest_rows(ctx))
    want = {x.strip().upper() for x in a.items.split(",") if x.strip()}
    reg = build(ctx)
    unknown = want - {l for l, _ in reg}
    if unknown:
        print(f"gate.py: unknown item label(s) {sorted(unknown)} for G{ctx.gate}; valid: {[l for l, _ in reg]}", file=sys.stderr)
        sys.exit(2)
    done = []
    for label, fn in reg:
        if want and label not in want:
            continue
        try:
            done.append(fn())
        except Exception as e:  # an unexpected input shape is a FAIL of that item, never a crash of the gate
            it = Item(label, "item raised an exception", f"gate.py G{ctx.gate}.{label}")
            it.fail("scripts/gate.py", 0, "GATEERR", f"{e.__class__.__name__}: {e}")
            done.append(it)
    now = datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")
    print(f"# gate.py G{ctx.gate} · loop {a.loop} of 3 · run {now} · root {root}")
    print("Mechanical items only; the reviewer completes the 04-T3 report (evidence = this run's run_logged log).\n")
    print("## Checklist")
    print("| # | Check (from the master prompt's gate row / milestone plan) | Method (scripts/gate.py item / reviewer id / command) | Result | Evidence |")
    print("|---|---|---|---|---|")
    for it in done:
        ev = "; ".join(it.evidence + it.notes) or "gate.py output (this log)"
        print(f"| {it.label} | {esc(it.check)} | {esc(it.method)} | {it.result} | {esc(ev)} |")
    fails = [(it, f) for it in done for f in it.fails]
    print("\n## Failures (file:line:RULE: message)")
    if not fails:
        print("none")
    for it, (f, ln, rule, msg, hard) in fails:
        print(f"{f}:{ln}:{rule}: [item {it.label}] {msg}{' [HARD-FAIL]' if hard else ''}")
    npass = sum(1 for it in done if not it.fails)
    hard = [it.label for it in done if any(f[4] for f in it.fails)]
    print(f"\ngate.py G{ctx.gate}: {npass} PASS, {len(done) - npass} FAIL, {len(fails)} failure lines; "
          f"hard-fail classes in items: {', '.join(hard) if hard else 'none'}")
    sys.exit(1 if npass != len(done) else 0)


if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
