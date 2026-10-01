#!/usr/bin/env python3
"""validate_analysis.py <page-slug> [--key <fileKey>] [--root DIR]

Validates docs/figma/analysis/<page-slug>.md (template 04-T11) against the page's
docs/figma/raw/<fileKey>/<page-slug>/nodes.json. Run by the analysis subagent before it reports
and by the orchestrator before accepting. Rules (file:line:RULE: message):
 COUNT     section 1 row count (table rows whose first cell is an SCR-/FRM-/CMP- id) equals the
           nodes.json depth-1 count; frames placed inside a SECTION (top-level frames by the
           figma_reconcile.py definition) are added, so every row-needing node is counted once
 CAND      every candidate from figma_reconcile.py --candidates has an `#### INT-` block or a
           NON-INTERACTIVE line carrying its node id
 BLOCK     every `### SCR-/FRM-/CMP-` block whose design context is cached (non-TRUNCATED cache
           file for its node, or `yes` in section 1's "Design context cached?" column) has the
           sub-headings **A.** to **E.** each with >= 1 non-empty row (a table row without empty
           cells, or text after the label)
 INTBLOCK  every `#### INT-` block has **B.** to **E.** each with >= 1 non-empty row
 REDLINE   every text layer of this page in docs/figma/text-layers.csv appears as the first cell
           of a row in a red-line scan table (header containing "Text layer node id")
 COUNTS    section 3 counts are present, numeric, and consistent: frames = section 1 rows =
           expected; components / component sets / variants / instances = nodes.json; text layers
           scanned = red-line rows; interaction candidates = candidates; INT rows = INT blocks;
           NON-INTERACTIVE rows = NON-INTERACTIVE lines; INT + NON-INTERACTIVE >= candidates;
           metadata-only-variant rows = section 1 rows so tagged; section 1's "Frames in
           nodes.json" / "Rows above" / "Interaction candidates" line agrees
 RANGE     every SCR/FRM/CMP/INT id defined in the file lies in a range allocated to this page in
           docs/figma/id-ranges.md (a line naming the page or slug with nnnn–nnnn ranges)
 END       the file ends with <!-- END OF FILE -->
 PHRASE / PLACE  truncation phrases and placeholder markers outside ```figma-copy / ```quote /
           ```output fences and backticks (validate_docs.py masks and patterns)
Exit 0 pass; 1 any failure; 2 page or index not found.
"""
import sys, re, os, csv, argparse, pathlib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import figma_fingerprint as ff  # noqa: E402
import figma_reconcile as fr    # noqa: E402
import validate_docs as vd      # noqa: E402

EMPTY = vd.EMPTY_CELL
COUNT_KEYS = ["frames", "components", "component sets", "variants", "instances", "text layers scanned",
              "interaction candidates", "INT rows", "NON-INTERACTIVE rows", "prototype starting points",
              "variables referenced", "metadata-only-variant rows"]
MARK = re.compile(r"^\*\*([A-E])\.\s[^*]*\*\*\s*[—:-]?\s*(.*)$")


def find_page(root, slug, key):
    base = pathlib.Path(root) / "docs/figma/raw"
    keys = [key] if key else sorted(d.name for d in base.iterdir() if (d / slug / "nodes.json").exists()) if base.is_dir() else []
    keys = [k for k in keys if (base / k / slug / "nodes.json").exists()]
    if len(keys) != 1:
        return None, keys
    pages, code = fr.load(root, keys[0])
    return next((p for p in pages if p.slug == slug), None), keys


def cells_of(line):
    return [c.strip() for c in line.strip().strip("|").split("|")]


def is_sep(line):
    return bool(re.match(r"^\|[\s:|-]+\|?$", line.strip()))


def nonempty_rows(chunk):
    """Count non-empty rows in a sub-heading's content (list of lines)."""
    n = 0
    in_table = False
    for l in chunk:
        s = l.strip()
        if not s:
            in_table = False
            continue
        if s.startswith("|"):
            if is_sep(s):
                in_table = True
                continue
            if not in_table:
                continue          # header row
            if all(c not in EMPTY for c in cells_of(s)):
                n += 1
            continue
        if s.startswith("#"):
            continue
        n += 1
    return n


def subheadings(lines, start, end):
    """{letter: (line no, content lines)} for **A.**..**E.** markers within lines[start:end]."""
    found, cur = {}, None
    for i in range(start, end):
        m = MARK.match(lines[i].strip())
        if m:
            cur = m.group(1)
            found.setdefault(cur, (i + 1, []))
            if m.group(2).strip():
                found[cur][1].append(m.group(2))
            continue
        if lines[i].startswith("#### "):
            cur = None
            continue
        if cur:
            found[cur][1].append(lines[i])
    return found


def main():
    ap = argparse.ArgumentParser(description="Validate one per-page Figma analysis file.",
                                 formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    ap.add_argument("slug", metavar="page-slug")
    ap.add_argument("--key", help="file key (needed only when several file keys have this page slug)")
    ap.add_argument("--root", default=".", help="project root (default: current directory)")
    a = ap.parse_args()
    root = pathlib.Path(a.root).resolve()
    page, keys = find_page(root, a.slug, a.key)
    path = root / "docs/figma/analysis" / f"{a.slug}.md"
    if page is None:
        why = f"several file keys have it ({', '.join(keys)}); pass --key" if len(keys) > 1 else "no nodes.json for this slug"
        ff.err(path, 0, "NOPAGE", why)
        sys.exit(2)
    key = keys[0]
    if not path.exists():
        ff.err(path, 0, "MISSING", "analysis file absent")
        sys.exit(1)
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.split("\n")
    errs = []

    def e(line, rule, msg):
        errs.append((path, line, rule, msg))

    # sections
    sec = {}
    for i, l in enumerate(lines):
        m = re.match(r"^##\s+(\d)\.", l)
        if m:
            sec[int(m.group(1))] = i
    bounds = sorted(sec.values()) + [len(lines)]

    def span(n):
        if n not in sec:
            return None
        s = sec[n]
        return s, next(b for b in bounds if b > s)

    # ---- COUNT: section 1
    expected = {n["id"] for n in page.nodes if n["depth"] == 1} | {n["id"] for n in page.top_level_frames()}
    s1 = span(1)
    s1rows = []
    s1_header = None
    if s1 is None:
        e(1, "COUNT", "no '## 1.' frame inventory section")
    else:
        for i in range(*s1):
            l = lines[i]
            if l.startswith("|") and not is_sep(l):
                c = cells_of(l)
                if re.fullmatch(r"\**(SCR|FRM|CMP)-\d{4}\**", c[0]):
                    s1rows.append((i + 1, c))
                elif s1_header is None:
                    s1_header = [x.lower() for x in c]
        if len(s1rows) != len(expected):
            present = {fr.node_id_in(c[2]) for _, c in s1rows if len(c) > 2}
            lack = sorted(expected - present)
            e(sec[1] + 1, "COUNT", f"section 1 has {len(s1rows)} rows; nodes.json depth-1 (plus frames in sections) "
                                   f"count is {len(expected)}" + (f"; no row for {', '.join(lack)}" if lack else ""))
    cached_col = next((j for j, h in enumerate(s1_header or []) if "design context cached" in h), None)
    s1_cached = {}
    for ln, c in s1rows:
        nid = fr.node_id_in(c[2]) if len(c) > 2 else None
        if cached_col is not None and cached_col < len(c):
            s1_cached[nid] = c[cached_col].strip().lower().startswith("yes")

    # ---- rows / candidates
    rows = fr.parse_rows(path)
    for r in rows:
        r["file"] = path
    covered = {r["node"] for r in rows if r["prefix"] in ("INT", "NI")}
    cands = page.candidates()
    blocks = {n["id"] for n in page.structural()}
    head_line = {r["node"]: r["line"] for r in rows if r["kind"] == "heading" and r["prefix"] in ("SCR", "FRM", "CMP")}
    for n, why in cands:
        if n["id"] not in covered:
            owner = page.block_owner(n["id"], blocks)
            e(head_line.get(owner, 1), "CAND", f'candidate {n["id"]} "{n["name"]}" ({", ".join(why)}) has no #### INT- block '
                                               f"or NON-INTERACTIVE line")

    # ---- BLOCK / INTBLOCK
    cdir = ff.raw_dir(root, key) / "get_design_context"
    heads = [i for i, l in enumerate(lines) if re.match(r"^###\s+\**(SCR|FRM|CMP)-\d{4}", l)]
    for i in heads:
        end = next((j for j in range(i + 1, len(lines)) if re.match(r"^(###\s|##\s)", lines[j])), len(lines))
        fields = lines[i].split("|")
        nid = fr.node_id_in(fields[2]) if len(fields) > 2 else None
        cached = bool(nid) and ((cdir / f"{ff.safe_id(nid)}.txt").exists() or s1_cached.get(nid, False))
        if cached:
            subs = subheadings(lines, i + 1, end)
            for letter in "ABCDE":
                if letter not in subs:
                    e(i + 1, "BLOCK", f"{fields[0].strip('# ').strip()} (node {nid}, design context cached) lacks sub-heading {letter}")
                elif nonempty_rows(subs[letter][1]) == 0:
                    e(subs[letter][0], "BLOCK", f"sub-heading {letter} of node {nid} has no non-empty row")
        ints = [j for j in range(i + 1, end) if re.match(r"^####\s+\**INT-\d{4}", lines[j])]
        for k, j in enumerate(ints):
            jend = ints[k + 1] if k + 1 < len(ints) else end
            subs = subheadings(lines, j + 1, jend)
            iid = lines[j].split("|")[0].strip("# *").strip()
            for letter in "BCDE":
                if letter not in subs:
                    e(j + 1, "INTBLOCK", f"{iid} lacks sub-heading {letter}")
                elif nonempty_rows(subs[letter][1]) == 0:
                    e(subs[letter][0], "INTBLOCK", f"sub-heading {letter} of {iid} has no non-empty row")

    # ---- REDLINE
    red_rows, header = set(), None
    for i, l in enumerate(lines):
        if not l.startswith("|"):
            header = None
            continue
        if is_sep(l):
            continue
        c = cells_of(l)
        if any("text layer node id" in x.lower() for x in c):
            header = c
            continue
        if header is not None:
            nid = fr.node_id_in(c[0])
            if nid:
                red_rows.add(nid)
    csv_path = root / "docs/figma/text-layers.csv"
    any_cached = any(s1_cached.values()) or any((cdir / f"{ff.safe_id(n)}.txt").exists() for n in blocks)
    if csv_path.exists():
        with open(csv_path, encoding="utf-8", newline="") as fh:
            layers = [r for r in csv.DictReader(fh) if r.get("page") == page.name]
        for r in layers:
            if r["node_id"] not in red_rows:
                e(head_line.get(r["frame_id"], 1), "REDLINE",
                  f'text layer {r["node_id"]} of frame {r["frame_id"]} ("{r["text"][:40]}") has no red-line scan row')
    elif any_cached:
        e(1, "REDLINE", "docs/figma/text-layers.csv absent although design context is cached; run scripts/extract_text.py")

    # ---- COUNTS
    s3 = span(3)
    int_ids = {r["id"] for r in rows if r["prefix"] == "INT"}
    ni_n = sum(1 for r in rows if r["prefix"] == "NI")
    if s3 is None:
        e(1, "COUNTS", "no '## 3.' page-level counts section")
    else:
        vals, vline = {}, sec[3] + 1
        for i in range(*s3):
            for part in lines[i].split("·"):
                m = re.match(r"^\s*([A-Za-z][A-Za-z -]*?)\s*:\s*(.+?)\s*$", part)
                if m and m.group(1) in COUNT_KEYS:
                    vals[m.group(1)] = (m.group(2), i + 1)
        want = {"frames": len(expected), "components": page.count("COMPONENT"),
                "component sets": page.count("COMPONENT_SET"), "variants": page.variants(),
                "instances": page.count("INSTANCE"), "text layers scanned": len(red_rows),
                "interaction candidates": len(cands), "INT rows": len(int_ids), "NON-INTERACTIVE rows": ni_n,
                "metadata-only-variant rows": sum(1 for _, c in s1rows if any("metadata-only-variant" in x for x in c))}
        for k in COUNT_KEYS:
            if k not in vals:
                e(vline, "COUNTS", f"count '{k}' missing")
                continue
            v, ln = vals[k]
            if not re.fullmatch(r"\d+", v):
                e(ln, "COUNTS", f"count '{k}' is not numeric: '{v}'")
                continue
            if k in want and int(v) != want[k]:
                e(ln, "COUNTS", f"'{k}: {v}' but the file/index gives {want[k]}")
        if "frames" in vals and vals["frames"][0].isdigit() and int(vals["frames"][0]) != len(s1rows):
            e(vals["frames"][1], "COUNTS", f"frames: {vals['frames'][0]} but section 1 has {len(s1rows)} rows")
        if len(int_ids) + ni_n < len(cands):
            e(vline, "COUNTS", f"INT rows {len(int_ids)} + NON-INTERACTIVE rows {ni_n} < interaction candidates {len(cands)}")
    if s1 is not None:
        for i in range(*s1):
            for label, want_v in (("Frames in nodes.json", len(expected)), ("Rows above", len(s1rows)),
                                  ("Interaction candidates", len(cands))):
                m = re.search(re.escape(label) + r":\s*([^·]+)", lines[i])
                if m and m.group(1).strip() != str(want_v):
                    e(i + 1, "COUNTS", f"'{label}: {m.group(1).strip()}' but the file/index gives {want_v}")

    # ---- RANGE
    rng_path = root / "docs/figma/id-ranges.md"
    ranges = []
    if rng_path.exists():
        for l in rng_path.read_text(encoding="utf-8", errors="replace").split("\n"):
            cs = [c.strip().lower() for c in l.strip().strip("|").split("|")] if l.startswith("|") else []
            names = {page.name.lower(), page.slug.lower()}
            if names & set(cs) or (not cs and any(re.search(r"(?<![\w-])" + re.escape(x) + r"(?![\w-])", l.lower()) for x in names)):
                ranges += [(int(x), int(y)) for x, y in re.findall(r"(\d{4})\s*(?:–|—|-|…|\.\.)\s*(\d{4})", l)]
        if not ranges:
            e(1, "RANGE", f"no range allocated to page '{page.name}' ({page.slug}) in {ff.rel(rng_path)}")
    else:
        e(1, "RANGE", f"{ff.rel(rng_path)} absent; ids cannot be checked against an allocated range")
    if ranges:
        defined = [(r["id"], r["line"]) for r in rows if r["prefix"] in ("SCR", "FRM", "CMP", "INT")]
        for ident, ln in defined:
            num = int(ident.split("-")[1])
            if not any(lo <= num <= hi for lo, hi in ranges):
                e(ln, "RANGE", f"{ident} outside the range(s) {', '.join(f'{lo:04d}–{hi:04d}' for lo, hi in ranges)} "
                               f"allocated to this page")

    # ---- END / PHRASE / PLACE
    if "<!-- END OF FILE -->" not in text[-400:]:
        e(len(lines), "END", "missing <!-- END OF FILE -->")
    for i, (l, _) in enumerate(vd.exempt_mask(lines), 1):
        if not l:
            continue
        m = vd.PHRASES.search(l)
        if m:
            e(i, "PHRASE", m.group(0))
        m = vd.PLACE.search(l)
        if m:
            e(i, "PLACE", m.group(0))

    errs.sort(key=lambda x: (x[1], x[2]))
    for f in errs:
        ff.err(*f)
    print(f"validate_analysis: {a.slug}: {len(s1rows)} frame rows, {len(cands)} candidates, {len(int_ids)} INT, "
          f"{ni_n} NON-INTERACTIVE, {len(red_rows)} red-line rows; {len(errs)} failures")
    sys.exit(1 if errs else 0)


if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
