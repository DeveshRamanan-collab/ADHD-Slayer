#!/usr/bin/env python3
"""extract_text.py <fileKey> [--root DIR]

Walks every cached get_design_context response in docs/figma/raw/<fileKey>/get_design_context/
and extracts the TEXT nodes into docs/figma/text-layers.csv (Phase 3):
  node_id, page, frame_id, frame_name, text, style_token, is_placeholder_guess
- Response formats: the MCP content wrapper [{"type":"text","text":...}] around generated markup
  (JSX/HTML elements carrying data-node-id; the text of an element is attributed to the innermost
  enclosing element with a data-node-id; paragraphs become line breaks; JSX string expressions
  such as {`Due 3:00 pm`} are unwrapped; other {expressions} are dropped), or a JSON node tree
  (type TEXT with characters).
- page/frame: the requested node of the cache file (file name = node id with ':' as '_') is
  looked up in nodes.json; the frame is its top-level frame ancestor (or itself).
- style_token: the design variables named in the text element's classes (var(--name, ...)), or
  for JSON its text style/bound variables; `none` when the response names none.
- is_placeholder_guess: text matches Loading|Lorem|Placeholder|\\.\\.\\.|… (case-insensitive) or a
  mode-sample pattern: {token}, [token], the words sample/example, XX.., 00:00, John/Jane Doe.
Frames (every top-level frame of every nodes.json) whose text was not extracted are listed in
docs/figma/text-layers.NOT-EXTRACTED.md with the reason:
  TRUNCATED              only a *.TRUNCATED.* response (or a metadata-only response) is cached
  metadata-only-variant  read-plan.md marks the frame skipped-variant (without a read plan: the
                         name carries a variant axis and a base frame exists)
  [NOT YET READ]         no response cached (or only some of its children when it was split)
A frame read as its children counts as extracted when every child (recursively) is extracted.

Rules: FORMAT (response holds neither data-node-id markup nor a JSON node tree), ORPHAN (cached
node id is in no nodes.json), NODES (index problems; exit 2).
Exit 0 ok; 1 FORMAT/ORPHAN problems (outputs still written); 2 no usable index.
"""
import sys, re, os, csv, html, json, argparse, pathlib, datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import figma_fingerprint as ff  # noqa: E402
import figma_reconcile as fr    # noqa: E402
import figma_read_plan as rp    # noqa: E402

PLACEHOLDER = re.compile(r"(?i)Loading|Lorem|Placeholder|\.\.\.|…")
MODE_SAMPLE = re.compile(r"\{[^}]+\}|\[[^\]]+\]|(?i:\b(?:sample|example)\b)|\bX{2,}\b|\b0?0:00\b|(?i:\b(?:john|jane) doe\b)")
VAR = re.compile(r"var\(--([^,)]+)")
COLUMNS = ["node_id", "page", "frame_id", "frame_name", "text", "style_token", "is_placeholder_guess"]


def node_from_file(name):
    stem = name.split(".")[0]
    return stem.replace("_", ":")


def scan(s):
    """Yield ('open', tag, attrs, selfclose) / ('close', tag) / ('text', str) events from markup."""
    i, n = 0, len(s)
    while i < n:
        j = s.find("<", i)
        if j < 0:
            yield ("text", s[i:])
            return
        if j + 1 < n and (s[j + 1].isalpha() or s[j + 1] == "/"):
            if j > i:
                yield ("text", s[i:j])
            k, depth, q = j + 1, 0, None
            while k < n:
                c = s[k]
                if q:
                    if c == q:
                        q = None
                elif c in "\"'`":
                    q = c
                elif c == "{":
                    depth += 1
                elif c == "}":
                    depth -= 1
                elif c == ">" and depth <= 0:
                    break
                k += 1
            body = s[j + 1:k]
            i = k + 1
            if body.startswith("/"):
                yield ("close", body[1:].strip().split()[0] if body[1:].strip() else "")
                continue
            selfclose = body.rstrip().endswith("/")
            m = re.match(r"([A-Za-z][\w.:-]*)", body)
            yield ("open", m.group(1) if m else "", body, selfclose)
        else:
            yield ("text", s[i:j + 1])
            i = j + 1


def attr(body, name):
    m = re.search(r'\b' + re.escape(name) + r'\s*=\s*(?:"([^"]*)"|\'([^\']*)\'|\{`([^`]*)`\})', body)
    return (m.group(1) or m.group(2) or m.group(3) or "") if m else None


def jsx_text(t):
    t = re.sub(r"\{\s*`([^`]*)`\s*\}", r"\1", t)
    t = re.sub(r'\{\s*"([^"]*)"\s*\}', r"\1", t)
    t = re.sub(r"\{\s*'([^']*)'\s*\}", r"\1", t)
    t = re.sub(r"\{[^{}]*\}", "", t)
    return html.unescape(t)


def from_markup(s):
    """Return list of (node id, text, style token) from data-node-id markup, or None if none present."""
    if "data-node-id" not in s:
        return None
    stack = []                      # (tag, node id or None)
    texts, classes, order = {}, {}, []
    for ev in scan(s):
        if ev[0] == "open":
            _, tag, body, selfclose = ev
            nid = attr(body, "data-node-id")
            cls = attr(body, "className") or attr(body, "class") or ""
            owner = nid or next((x[1] for x in reversed(stack) if x[1]), None)
            if nid and nid not in texts:
                texts[nid], classes[nid] = [], []
                order.append(nid)
            if owner and cls:
                classes[owner].append(cls)
            if tag.lower() == "br" and owner:
                texts[owner].append("\n")
            if not selfclose:
                stack.append((tag, nid))
        elif ev[0] == "close":
            tag = ev[1]
            for i in range(len(stack) - 1, -1, -1):
                if stack[i][0] == tag:
                    owner = next((x[1] for x in reversed(stack[:i + 1]) if x[1]), None)
                    if owner and tag.lower() in ("p", "div", "span", "li") and not stack[i][1]:
                        texts[owner].append("\n")
                    del stack[i:]
                    break
        else:
            owner = next((x[1] for x in reversed(stack) if x[1]), None)
            if owner:
                texts[owner].append(ev[1])
    out = []
    for nid in order:
        raw = jsx_text("".join(texts[nid]))
        lines = [re.sub(r"\s+", " ", l).strip() for l in raw.split("\n")]
        text = "\n".join(l for l in lines if l)
        if not text:
            continue
        toks = []
        for c in classes[nid]:
            for v in VAR.findall(c):
                v = v.replace("\\/", "/").replace("\\", "").strip()
                if v not in toks:
                    toks.append(v)
        out.append((nid, text, ";".join(toks) or "none"))
    return out


def from_json(obj):
    out = []

    def walk(n):
        if isinstance(n, dict):
            if str(n.get("type", "")).upper() == "TEXT" and "id" in n:
                text = n.get("characters") or n.get("text") or ""
                tok = []
                st = n.get("styles")
                if isinstance(st, dict):
                    tok += [str(v) for v in st.values()]
                if n.get("textStyleId"):
                    tok.append(str(n["textStyleId"]))
                bv = n.get("boundVariables")
                if isinstance(bv, dict):
                    tok += sorted(bv.keys())
                out.append((str(n["id"]), text, ";".join(tok) or "none"))
            for v in n.values():
                walk(v)
        elif isinstance(n, list):
            for v in n:
                walk(v)
    walk(obj)
    return out


def parse_response(text):
    """Return ('ok', rows) / ('metadata-only', []) / ('format', None)."""
    kind, payload = ff.unwrap(text)
    if kind == "json":
        rows = from_json(payload)
        return ("ok", rows) if rows or isinstance(payload, (dict, list)) else ("format", None)
    rows = from_markup(payload)
    if rows is not None:
        return "ok", rows
    if re.search(r'<[A-Za-z][\w-]*\s[^>]*\bid\s*=\s*"I?\d+:\d+', payload):
        return "metadata-only", []
    return "format", None


def placeholder_guess(t):
    return bool(PLACEHOLDER.search(t) or MODE_SAMPLE.search(t))


def plan_statuses(root):
    p = pathlib.Path(root) / "docs/figma/read-plan.md"
    st = {}
    if not p.exists():
        return st, False
    for line in p.read_text(encoding="utf-8", errors="replace").split("\n"):
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) == 11 and cells[0].isdigit() and cells[2] == "get_design_context":
            st.setdefault(cells[3], set()).add(cells[10])
    return st, True


def main():
    ap = argparse.ArgumentParser(description="Extract TEXT layers from cached design context.",
                                 formatter_class=argparse.RawDescriptionHelpFormatter, epilog=__doc__)
    ap.add_argument("fileKey")
    ap.add_argument("--root", default=".", help="project root (default: current directory)")
    a = ap.parse_args()
    root = pathlib.Path(a.root).resolve()
    pages, code = fr.load(root, a.fileKey)
    if code:
        print("extract_text: stopped (exit 2): fix the index problems above first")
        sys.exit(2)
    where = {}                                  # node id -> (page, top frame node)
    tops = []
    for p in pages:
        top_ids = {n["id"] for n in p.top_level_frames()}
        tops += [(p, n) for n in p.top_level_frames()]
        for n in p.nodes:
            cur, frame = n["id"], None
            while cur and cur != p.id:
                if cur in top_ids:
                    frame = p.by_id[cur]
                    break
                cur = p.by_id.get(cur, {}).get("parentId")
            where[n["id"]] = (p, frame)
    cdir = ff.raw_dir(root, a.fileKey) / "get_design_context"
    probs, rows, ok_nodes, trunc_nodes, meta_nodes = [], [], set(), {}, set()
    for f in sorted(cdir.iterdir()) if cdir.is_dir() else []:
        if not f.is_file():
            continue
        nid = node_from_file(f.name)
        if ".TRUNCATED." in f.name:
            trunc_nodes[nid] = f
            continue
        if nid not in where:
            probs.append((f, 1, "ORPHAN", f"cached node {nid} is in no nodes.json of {a.fileKey}"))
            continue
        status, found = parse_response(f.read_text(encoding="utf-8", errors="replace"))
        if status == "format":
            probs.append((f, 1, "FORMAT", "response holds neither data-node-id markup nor a JSON node tree"))
            continue
        if status == "metadata-only":
            meta_nodes.add(nid)
            continue
        ok_nodes.add(nid)
        p, frame = where[nid]
        frame = frame or p.by_id.get(nid)
        for tid, text, tok in found:
            rows.append({"node_id": tid, "page": p.name, "frame_id": frame["id"], "frame_name": frame["name"],
                         "text": text, "style_token": tok, "is_placeholder_guess": "true" if placeholder_guess(text) else "false"})
    out_csv = root / "docs/figma/text-layers.csv"
    out_csv.parent.mkdir(parents=True, exist_ok=True)
    with open(out_csv, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=COLUMNS)
        w.writeheader()
        w.writerows(rows)
    # NOT-EXTRACTED
    plan, has_plan = plan_statuses(root)

    def covered(p, nid, depth=0):
        if nid in ok_nodes:
            return True
        kids = p.children.get(nid, [])
        return bool(kids) and depth < 8 and all(covered(p, k, depth + 1) for k in kids)

    def unread_children(p, nid):
        return [k for k in p.children.get(nid, []) if not covered(p, k)]

    missing = []
    for p, n in tops:
        if covered(p, n["id"]):
            continue
        nid = n["id"]
        if nid in trunc_nodes or nid in meta_nodes:
            src = trunc_nodes.get(nid)
            detail = os.path.relpath(src, root) if src else "design-context response holds metadata only"
            kids = unread_children(p, nid)
            if kids and any(k in ok_nodes for k in p.children.get(nid, [])):
                detail += f"; children not yet read: {', '.join(kids)}"
            missing.append((p, n, "TRUNCATED", detail))
            continue
        skipped = "skipped-variant" in plan.get(nid, set())
        frames = [x for q, x in tops if q is p]
        base = rp.base_of(p, n, frames)
        if skipped or (not has_plan and rp.axes_of(n["name"]) and base):
            missing.append((p, n, "metadata-only-variant", f"metadata-only-variant of {base or 'base frame not found by name'}"))
            continue
        kids = [k for k in p.children.get(nid, []) if covered(p, k)]
        detail = (f"split into children; read: {', '.join(kids)}; not yet read: {', '.join(unread_children(p, nid))}"
                  if kids else "no design-context response cached")
        missing.append((p, n, "[NOT YET READ]", detail))
    now = datetime.datetime.now().astimezone().strftime("%Y-%m-%dT%H:%M:%S%z")
    md = ["# TEXT LAYERS NOT EXTRACTED — generated by scripts/extract_text.py (do not edit by hand)",
          f"Generated: {now} · File key: `{a.fileKey}` · Top-level frames: {len(tops)} · extracted: {len(tops) - len(missing)} · "
          f"not extracted: {len(missing)} · text rows written to docs/figma/text-layers.csv: {len(rows)}",
          f"Read plan used for metadata-only-variant: {'docs/figma/read-plan.md' if has_plan else 'none (name-based variant detection)'}",
          "", "| Page | Frame id | Frame name | Reason | Detail |", "|---|---|---|---|---|"]
    for p, n, reason, detail in missing:
        md.append(f"| {p.name} | {n['id']} | {n['name'].replace('|', '/')} | {reason} | {detail} |")
    if not missing:
        md.append("| all pages | none | none | none (every top-level frame extracted) | none |")
    md += ["", "<!-- END OF FILE -->", ""]
    out_md = root / "docs/figma/text-layers.NOT-EXTRACTED.md"
    out_md.write_text("\n".join(md), encoding="utf-8")
    for f in probs:
        ff.err(*f)
    print(f"extract_text: {len(ok_nodes)} responses parsed, {len(trunc_nodes)} TRUNCATED, {len(rows)} text rows -> "
          f"{ff.rel(out_csv)}; {len(missing)} frames not extracted -> {ff.rel(out_md)}; problems {len(probs)}")
    sys.exit(1 if probs else 0)


if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
