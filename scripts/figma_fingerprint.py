#!/usr/bin/env python3
"""figma_fingerprint.py <fileKey> [--page <slug>] [--build <slug>=<pageNodeId> ...] [--check] [--root DIR]

Canonical structural fingerprints of a Figma file (Phase 1.3, prompts/06_SCRIPT_SPECS.md).

Reads docs/figma/raw/<fileKey>/<page-slug>/nodes.json (all pages, or one with --page).
Per page: the sorted list of (id, name, type, parentId, width, height) tuples, with any
field whose name contains url/time/date/thumbnail/version/expires removed first, is
serialised as canonical JSON (sort_keys=True, separators without spaces, UTF-8) and hashed
with SHA-256. Root fingerprint = SHA-256 over the page fingerprints (hex) joined with "\\n"
in page order. Page order = order of the pages in the cached root get_metadata response
(docs/figma/raw/<fileKey>/get_metadata/root.txt); pages it does not list follow in slug order.

Writes/updates the "fingerprint" field inside each nodes.json (only when it changed) and
prints a Markdown table for docs/FIGMA_VERSION_LOCK.md.

--build <slug>=<pageNodeId>  first writes docs/figma/raw/<fileKey>/<slug>/nodes.json from the
    cached get_metadata response docs/figma/raw/<fileKey>/get_metadata/<id with : as _>.txt.
    Accepted formats: the MCP content wrapper [{"type":"text","text":...}] around either
    JSON (a node tree with id/name/type/children, REST-style "document"/"nodes", or a flat
    normalised list) or the XML/text node list (tags with id/name attributes; the tag or a
    "type" attribute gives the type), and the root page listing ("- <id>: <name>").
    An unrecognised format exits 2 (UNRECOGNISED): write nodes.json by hand once and log D-nnn.
    Nodes are never guessed: only nodes present in the response are written.
--check  compute only; exit 1 (DRIFT) if a stored fingerprint differs; writes nothing.
--root DIR  project root (default: current directory); used for fixtures.

Output lines on failure: file:line:RULE: message. Rules: NODES (nodes.json unreadable or
malformed), PAGE (--page slug absent), CACHE (cached response missing or TRUNCATED),
UNRECOGNISED (response format), DRIFT (--check mismatch).
Exit: 0 ok; 1 malformed index or drift; 2 missing input or unrecognised format.
"""
import sys, re, os, json, hashlib, argparse, pathlib, html

DROP = ("url", "time", "date", "thumbnail", "version", "expires")
FIELDS = ("id", "name", "type", "parentId", "width", "height")
NODE_ID = re.compile(r"I?\d+:\d+(?:;\d+:\d+)*")
TOOL_DIR = re.compile(r"^(get_|search_|whoami)")
TAG_TYPE = {"SYMBOL": "COMPONENT", "PAGE": "CANVAS", "DOCUMENT": "DOCUMENT", "ROUNDED_RECTANGLE": "RECTANGLE"}


def rel(path):
    """Path for messages: relative to the current directory when possible."""
    try:
        return os.path.relpath(str(path))
    except ValueError:
        return str(path)


def err(path, line, rule, msg):
    print(f"{rel(path)}:{line}:{rule}: {msg}")


def raw_dir(root, key):
    return pathlib.Path(root) / "docs/figma/raw" / key


def safe_id(node_id):
    return node_id.replace("-", ":").replace(":", "_")


def num(v):
    if isinstance(v, bool) or v is None:
        return None
    if isinstance(v, (int, float)):
        return int(v) if float(v).is_integer() else round(float(v), 3)
    try:
        f = float(str(v))
    except ValueError:
        return None
    return int(f) if f.is_integer() else round(f, 3)


# ---------------------------------------------------------------- response parsing
def unwrap(text):
    """Return ("json", obj) or ("text", str) after removing MCP content wrappers."""
    s = text.strip()
    try:
        obj = json.loads(s)
    except (ValueError, TypeError):
        return "text", text
    items = None
    if isinstance(obj, list) and obj and all(isinstance(x, dict) and "type" in x for x in obj) \
            and any(x.get("type") == "text" for x in obj):
        items = obj
    elif isinstance(obj, dict) and isinstance(obj.get("content"), list):
        items = obj["content"]
    if items is not None:
        inner = "\n".join(x.get("text", "") for x in items if isinstance(x, dict) and x.get("type") == "text")
        return unwrap(inner)
    if isinstance(obj, str):
        return "text", obj
    return "json", obj


def parse_page_list(text):
    """Root listing lines '- 0:1: Cover' -> [(id, name)]."""
    out = []
    for line in text.split("\n"):
        m = re.match(r"^\s*-\s+(\d+:\d+):\s*(.+?)\s*$", line)
        if m:
            out.append((m.group(1), m.group(2)))
    return out


def _json_nodes(obj, page_id):
    """Walk a JSON node tree; return (page_meta, nodes)."""
    page_meta = {}
    nodes = []

    def size(n):
        w, h = n.get("width"), n.get("height")
        if w is None and isinstance(n.get("absoluteBoundingBox"), dict):
            w, h = n["absoluteBoundingBox"].get("width"), n["absoluteBoundingBox"].get("height")
        if w is None and isinstance(n.get("size"), dict):
            w, h = n["size"].get("x"), n["size"].get("y")
        return num(w), num(h)

    def walk(n, parent, depth):
        if not isinstance(n, dict) or "id" not in n:
            return
        nid = str(n["id"])
        ntype = str(n.get("type", "")).upper()
        if nid == page_id or ntype in ("CANVAS", "DOCUMENT") and parent is None:
            if nid == page_id or ntype == "CANVAS":
                page_meta.update(name=n.get("name"), type=ntype or "CANVAS")
            for c in n.get("children", []) or []:
                walk(c, page_id, 1)
            return
        w, h = size(n)
        rec = {"id": nid, "name": str(n.get("name", "")), "type": ntype, "parentId": parent,
               "depth": depth, "width": w, "height": h}
        reactions = n.get("reactions") or n.get("interactions")
        if reactions:
            rec["reactions"] = len(reactions) if isinstance(reactions, list) else 1
        mcn = n.get("mainComponentName") or n.get("componentName") or (
            n.get("mainComponent", {}).get("name") if isinstance(n.get("mainComponent"), dict) else None)
        if mcn:
            rec["mainComponentName"] = str(mcn)
        nodes.append(rec)
        for c in n.get("children", []) or []:
            walk(c, nid, depth + 1)

    roots = []
    if isinstance(obj, dict) and isinstance(obj.get("nodes"), list):
        flat = obj["nodes"]          # already normalised: keep, recompute nothing
        for n in flat:
            if isinstance(n, dict) and "id" in n:
                nodes.append({k: n.get(k) for k in ("id", "name", "type", "parentId", "depth", "width", "height")}
                             | {k: n[k] for k in ("reactions", "mainComponentName") if k in n})
        if obj.get("page"):
            page_meta.update(name=obj.get("page"), type=obj.get("pageType", "CANVAS"))
        return page_meta, nodes
    if isinstance(obj, dict) and isinstance(obj.get("nodes"), dict):
        roots = [v.get("document", v) for v in obj["nodes"].values() if isinstance(v, dict)]
    elif isinstance(obj, dict) and isinstance(obj.get("document"), dict):
        roots = [obj["document"]]
    elif isinstance(obj, dict) and "id" in obj:
        roots = [obj]
    elif isinstance(obj, list):
        roots = [x for x in obj if isinstance(x, dict) and "id" in x]
    for r in roots:
        walk(r, None if str(r.get("id")) == page_id else page_id, 1)
    for n in nodes:
        if n["parentId"] is None:
            n["parentId"] = page_id
    return page_meta, nodes


TAG = re.compile(r"""<(/?)([A-Za-z][\w:.-]*)((?:\s+[^\s=/>]+(?:\s*=\s*(?:"[^"]*"|'[^']*'))?)*)\s*(/?)>""")
ATTR = re.compile(r"""([^\s=/>]+)\s*=\s*(?:"([^"]*)"|'([^']*)')""")


def _xml_nodes(text, page_id):
    page_meta = {}
    nodes = []
    depth_of = {page_id: 0}
    stack = []   # (tag, node id or None)
    for m in TAG.finditer(text):
        closing, tag, attrs, selfclose = m.group(1), m.group(2), m.group(3), m.group(4)
        if closing:
            for i in range(len(stack) - 1, -1, -1):
                if stack[i][0] == tag:
                    del stack[i:]
                    break
            continue
        a = {k: html.unescape(v1 or v2) for k, v1, v2 in ATTR.findall(attrs)}
        nid = a.get("id")
        if not nid or not NODE_ID.fullmatch(nid):
            if not selfclose:
                stack.append((tag, None))
            continue
        ntype = (a.get("type") or TAG_TYPE.get(tag.upper().replace("-", "_"), tag.upper().replace("-", "_"))).upper()
        if nid == page_id:
            page_meta.update(name=a.get("name"), type=ntype)
            if not selfclose:
                stack.append((tag, nid))
            continue
        parent = next((s[1] for s in reversed(stack) if s[1]), page_id)
        depth = depth_of.get(parent, 0) + 1
        depth_of[nid] = depth
        rec = {"id": nid, "name": a.get("name", ""), "type": ntype, "parentId": parent, "depth": depth,
               "width": num(a.get("width")), "height": num(a.get("height"))}
        if a.get("reactions") or a.get("interactions"):
            rec["reactions"] = num(a.get("reactions") or a.get("interactions")) or 1
        if a.get("mainComponentName") or a.get("componentName"):
            rec["mainComponentName"] = a.get("mainComponentName") or a.get("componentName")
        nodes.append(rec)
        if not selfclose:
            stack.append((tag, nid))
    return page_meta, nodes


def parse_metadata(text, page_id):
    """Return dict(format, page_meta, nodes, pages) or None if unrecognised."""
    kind, payload = unwrap(text)
    if kind == "json":
        meta, nodes = _json_nodes(payload, page_id)
        if nodes or meta:
            return {"format": "json", "page_meta": meta, "nodes": nodes, "pages": []}
        return None
    if re.search(r"<[A-Za-z][\w-]*\s[^>]*\bid\s*=\s*\"" + r"I?\d+:\d+", payload):
        meta, nodes = _xml_nodes(payload, page_id)
        return {"format": "xml", "page_meta": meta, "nodes": nodes, "pages": []}
    pages = parse_page_list(payload)
    if pages:
        return {"format": "page-list", "page_meta": {}, "nodes": [], "pages": pages}
    return None


# ---------------------------------------------------------------- index loading
def root_page_order(root, key):
    p = raw_dir(root, key) / "get_metadata" / "root.txt"
    if not p.exists():
        return []
    res = parse_metadata(p.read_text(encoding="utf-8", errors="replace"), "root")
    return [pid for pid, _ in res["pages"]] if res else []


def root_page_names(root, key):
    p = raw_dir(root, key) / "get_metadata" / "root.txt"
    if not p.exists():
        return {}
    res = parse_metadata(p.read_text(encoding="utf-8", errors="replace"), "root")
    return dict(res["pages"]) if res else {}


def validate_index(path, data, text):
    """Return list of (line, message) problems for one nodes.json."""
    probs = []
    if not isinstance(data, dict):
        return [(1, "top level is not an object")]
    for k in ("page", "pageId", "nodes"):
        if k not in data:
            probs.append((1, f"missing key '{k}'"))
    if probs:
        return probs
    if not isinstance(data["nodes"], list):
        return [(1, "'nodes' is not a list")]
    seen = set()
    for n in data["nodes"]:
        nid = n.get("id") if isinstance(n, dict) else None
        line = 1
        if nid:
            i = text.find(f'"id": "{nid}"')
            i = i if i >= 0 else text.find(f'"id":"{nid}"')
            line = text.count("\n", 0, i) + 1 if i >= 0 else 1
        if not isinstance(n, dict):
            probs.append((line, "node is not an object"))
            continue
        for k in ("id", "name", "type", "parentId", "depth"):
            if k not in n or n[k] is None:
                probs.append((line, f"node {nid or '?'} lacks '{k}'"))
        if nid and not NODE_ID.fullmatch(str(nid)):
            probs.append((line, f"node id '{nid}' is not a Figma node id"))
        if nid in seen:
            probs.append((line, f"node id {nid} appears twice"))
        seen.add(nid)
    return probs


def load_pages(root, key, page=None, report=True):
    """Return (pages, failures). pages: list of dicts {slug, path, data, text} in page order."""
    base = raw_dir(root, key)
    pages, fails = [], []
    if not base.is_dir():
        return [], [(base, 0, "NODES", f"no cache folder for file key {key}")]
    for d in sorted(base.iterdir()):
        if not d.is_dir() or TOOL_DIR.match(d.name):
            continue
        p = d / "nodes.json"
        if not p.exists():
            continue
        if page and d.name != page:
            continue
        text = p.read_text(encoding="utf-8", errors="replace")
        try:
            data = json.loads(text)
        except ValueError as e:
            fails.append((p, getattr(e, "lineno", 1), "NODES", f"invalid JSON: {e}"))
            continue
        probs = validate_index(p, data, text)
        if probs:
            fails += [(p, ln, "NODES", m) for ln, m in probs]
            continue
        pages.append({"slug": d.name, "path": p, "data": data, "text": text})
    order = root_page_order(root, key)
    pages.sort(key=lambda pg: (order.index(pg["data"]["pageId"]) if pg["data"]["pageId"] in order else len(order),
                               pg["slug"]))
    if report:
        for f in fails:
            err(*f)
    return pages, fails


# ---------------------------------------------------------------- fingerprints
def kept_fields():
    return [f for f in FIELDS if not any(b in f.lower() for b in DROP)]


def page_fingerprint(nodes):
    fields = kept_fields()
    rows = []
    for n in nodes:
        clean = {k: v for k, v in n.items() if not any(b in k.lower() for b in DROP)}
        rows.append([clean.get(f) for f in fields])
    rows.sort(key=lambda r: json.dumps(r, sort_keys=True, separators=(",", ":"), ensure_ascii=False))
    canon = json.dumps(rows, sort_keys=True, separators=(",", ":"), ensure_ascii=False)
    return hashlib.sha256(canon.encode("utf-8")).hexdigest()


def root_fingerprint(page_fps):
    return hashlib.sha256("\n".join(page_fps).encode("utf-8")).hexdigest()


def write_index(path, data):
    ordered = {"page": data["page"], "pageId": data["pageId"], "fingerprint": data.get("fingerprint", "")}
    for k, v in data.items():
        if k not in ordered and k != "nodes":
            ordered[k] = v
    ordered["nodes"] = data["nodes"]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(ordered, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")


def build(root, key, spec):
    """--build slug=pageNodeId. Returns exit code (0 ok, 2 failure)."""
    if "=" not in spec:
        err("--build", 0, "CACHE", f"expected <slug>=<pageNodeId>, got '{spec}'")
        return 2
    slug, page_id = spec.split("=", 1)
    page_id = page_id.replace("-", ":")
    cache = raw_dir(root, key) / "get_metadata" / f"{safe_id(page_id)}.txt"
    if not cache.exists():
        trunc = cache.with_name(f"{safe_id(page_id)}.TRUNCATED.txt")
        why = "only a TRUNCATED response is cached; re-plan as children" if trunc.exists() else "not cached"
        err(cache, 0, "CACHE", f"get_metadata for {page_id}: {why}")
        return 2
    res = parse_metadata(cache.read_text(encoding="utf-8", errors="replace"), page_id)
    if res is None or (res["format"] == "page-list"):
        err(cache, 1, "UNRECOGNISED", "response format not recognised (neither JSON node tree nor XML node list); "
                                      "write nodes.json by hand from this response once and log D-nnn")
        return 2
    name = res["page_meta"].get("name") or root_page_names(root, key).get(page_id)
    if not name:
        err(cache, 1, "UNRECOGNISED", f"page name for {page_id} is in neither the response nor the root listing")
        return 2
    out = raw_dir(root, key) / slug / "nodes.json"
    old = {}
    if out.exists():
        try:
            old = json.loads(out.read_text(encoding="utf-8"))
        except ValueError:
            old = {}
    data = {"page": name, "pageId": page_id, "fingerprint": old.get("fingerprint", ""),
            "pageType": res["page_meta"].get("type") or "CANVAS", "source": os.path.relpath(cache, root),
            "nodes": res["nodes"]}
    if {k: v for k, v in old.items() if k != "fingerprint"} != {k: v for k, v in data.items() if k != "fingerprint"}:
        data["fingerprint"] = ""
        write_index(out, data)
        print(f"built {rel(out)}: {len(res['nodes'])} nodes from {res['format']} response")
    else:
        print(f"unchanged {rel(out)}: {len(res['nodes'])} nodes")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[2], formatter_class=argparse.RawDescriptionHelpFormatter,
                                 epilog=__doc__)
    ap.add_argument("fileKey")
    ap.add_argument("--page", help="one page slug only (no root fingerprint is printed)")
    ap.add_argument("--build", action="append", default=[], metavar="SLUG=PAGEID",
                    help="write <slug>/nodes.json from the cached get_metadata response first (repeatable)")
    ap.add_argument("--check", action="store_true", help="compare with stored fingerprints; write nothing")
    ap.add_argument("--root", default=".", help="project root (default: current directory)")
    a = ap.parse_args()
    root = pathlib.Path(a.root).resolve()
    code = 0
    for spec in a.build:
        code = max(code, build(root, a.fileKey, spec))
    if code:
        sys.exit(code)
    pages, fails = load_pages(root, a.fileKey, a.page)
    if a.page and not pages and not fails:
        err(raw_dir(root, a.fileKey) / a.page / "nodes.json", 0, "PAGE", f"no nodes.json for page slug '{a.page}'")
        sys.exit(2)
    if not pages and not fails:
        err(raw_dir(root, a.fileKey), 0, "NODES", "no <page-slug>/nodes.json found")
        sys.exit(2)
    rows, fps, total = [], [], 0
    for pg in pages:
        d = pg["data"]
        fp = page_fingerprint(d["nodes"])
        fps.append(fp)
        total += len(d["nodes"])
        rows.append(("page", d["page"], d["pageId"], len(d["nodes"]), fp))
        if d.get("fingerprint") != fp:
            if a.check:
                err(pg["path"], 1, "DRIFT", f"stored {d.get('fingerprint') or 'none'} != computed {fp}")
                code = 1
            else:
                d["fingerprint"] = fp
                write_index(pg["path"], d)
    print("| Scope | Page | Page id | Nodes | Fingerprint (SHA-256) |")
    print("|---|---|---|---|---|")
    for r in rows:
        print("| %s | %s | %s | %d | `%s` |" % r)
    if not a.page and not fails:
        print("| root | all %d pages, in page order | root | %d | `%s` |" % (len(pages), total, root_fingerprint(fps)))
    elif a.page:
        print(f"root fingerprint not computed: --page {a.page} limits the run to one page")
    if fails:
        print(f"figma_fingerprint: {len(fails)} failures; root fingerprint withheld")
        code = 1
    sys.exit(code)


if __name__ == "__main__":
    main()
# <!-- END OF FILE -->
