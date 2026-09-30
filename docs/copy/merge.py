import json, re, sys, os
spec = json.load(open("slots.json"))
banned = re.compile(r"\b(due|onset|wear(s|ing)? off|booster|predict\w*|optimal)\b", re.I)
deck, problems = {}, []
FIX = {"Everything due today is logged.": "Everything for today is logged.",
       "Everything due is logged.": "All of today’s is logged. Tidy."}
for i in range(1, 7):
    f = f"batch{i}.json"
    if not os.path.exists(f):
        problems.append(f"missing {f}"); continue
    for k, v in json.load(open(f)).items():
        if k not in spec: problems.append(f"{f}: unknown slot {k}"); continue
        s = spec[k]
        good = []
        for x in v:
            t = FIX.get(x["t"], x["t"]).replace("'", "’").strip()
            why = None
            if "—" in t or "–" in t or " - " in t: why = "dash"
            elif len(t) > s["maxCharacters"]: why = f"too long {len(t)}"
            elif any(t.count("{" + p + "}") != 1 for p in s["placeholders"]): why = "placeholder"
            elif set(re.findall(r"\{(\w+)\}", t)) - set(s["placeholders"]): why = "extra placeholder"
            elif banned.search(t): why = "banned word"
            elif s["tone"] == "serious" and x["f"]: why = "funny in serious slot"
            if why: problems.append(f"{k}: {why}: {t}")
            else: good.append({"t": t, "f": bool(x["f"])})
        seen, uniq = set(), []
        for g in good:
            key = g["t"].lower()
            if key not in seen: seen.add(key); uniq.append(g)
        deck[k] = uniq
missing = [k for k in spec if k not in deck]
print("slots:", len(deck), "of", len(spec), "| missing:", missing)
counts = sorted((len(v), k) for k, v in deck.items())
print("fewest variants:", counts[:5])
print("problems:", len(problems)); print("\n".join(problems[:40]))
if "--write" in sys.argv:
    out = "/Users/deveshramanan/ADHD Slayer/app/FocusApp/FocusApp/Copy.json"
    json.dump(deck, open(out, "w"), ensure_ascii=False, separators=(",", ":"))
    print("wrote", out, os.path.getsize(out), "bytes")
