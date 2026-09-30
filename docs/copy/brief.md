# Copy brief: 100 versions of every sentence

You are writing in-app copy for "Focus", an iPhone day planner for adults with ADHD that plans each day around their own medication rhythm. The app's look is quiet and elegant (serif headings, lots of space). The voice is a warm, slightly funny friend who also has ADHD: plain words, short sentences, never preachy, never clinical, never shaming.

For EVERY slot in your batch file, write EXACTLY 100 distinct versions. Each version must mean the same thing as the slot's context and example, so any of them can be shown on any day.

## Hard rules (every version)
1. No dashes used as punctuation: never use the em dash (—), the en dash (–), or a spaced hyphen ( - ). Hyphens inside ordinary words (check-in, wind-down) are fine. Use full stops, commas or colons instead.
2. Keep every placeholder exactly as written in the slot, e.g. {name}, {time}, {count}, {task}, {event}, {done}, {total}, {minutes}. Every version must contain every placeholder of its slot, exactly once each, spelled exactly the same. Never add placeholders that aren't in the slot.
3. Never exceed the slot's maxCharacters (count the placeholder text as written, e.g. "{time}" is 6 characters).
4. No emoji. No hashtags. At most 3 exclamation marks across the whole slot. Use the typographic apostrophe ’ (U+2019), not '.
5. Never give medical advice or anything that could read as advice about medication, doses, timing of doses, sleep medicine, diagnosis or treatment. Never joke about medication, doses, pills, drugs, overdose, addiction, mental illness, self-harm, weight or food restriction, money problems, or anyone's worth.
6. Never shame or guilt: no "you failed", "lazy", "finally", "should have", streak pressure, or sarcasm aimed at the reader.
7. Match the slot's context exactly (e.g. trialTitle must not state a trial length; trialWhy must keep the idea that ADHD takes time to understand, that it's fair to see if the app works for you, and that cancelling is easy; socialMessage is a text the person may send a friend, so it must be kind to the friend and make sense to them).
8. Headlines stay short. Headline-style slots (short maxCharacters, no full sentence in the example) may omit the final full stop if the example has none.

## Tone per slot
- "serious": all 100 plain, kind and clear. No jokes at all. Vary wording only. Mark every version "f": false.
- "light": about 70 plain and warm ("f": false) and about 30 with a gentle smile ("f": true).
- "playful": about 40 plain ("f": false) and about 60 properly funny ("f": true).

## What "funny for ADHD" means
Jokes should land for people with ADHD because they recognise themselves, never because they're being mocked. Good territory: time blindness ("5 minutes" that became an hour), hyperfocus rabbit holes, 47 open tabs, the doom pile, walking into a room and forgetting why, starting four hobbies this month, the dopamine hunt, side quests, "I'll do it later" optimism, body doubling, snack-based motivation, losing your phone while holding it, reading the same sentence six times, the task that takes 5 minutes but has lived on the list for 3 weeks, alarms for your alarms, the brain as a browser or a radio between stations, squirrels (sparingly). Keep it affectionate, specific and brief. Avoid the tired lines: "everyone's a little ADHD", "squirrel!" as the whole joke, anything about being "crazy".

## Output
Write ONE JSON file for your batch, at the path given to you, shaped like:
{"slotName": [{"t": "text", "f": false}, ... 100 items], "nextSlot": [...]}
Keys must be the slot names from your batch file. UTF-8, valid JSON.

## Self-check before you finish (run it)
Run this with python3, fix every problem it prints, and run it again until it prints OK:

import json,re,sys
spec=json.load(open(SLOTS_PATH)); out=json.load(open(OUT_PATH))
bad=[]
for k,s in spec.items():
    v=out.get(k,[])
    if len(v)!=100: bad.append(f"{k}: {len(v)} versions")
    texts=[x["t"] for x in v]
    if len(set(t.lower() for t in texts))!=len(texts): bad.append(f"{k}: duplicates")
    for x in v:
        t=x["t"]
        if "—" in t or "–" in t or " - " in t: bad.append(f"{k}: dash in: {t}")
        if len(t)>s["maxCharacters"]: bad.append(f"{k}: too long ({len(t)}): {t}")
        for p in s["placeholders"]:
            if t.count("{"+p+"}")!=1: bad.append(f"{k}: placeholder {p} count in: {t}")
        extra=set(re.findall(r"\{(\w+)\}",t))-set(s["placeholders"])
        if extra: bad.append(f"{k}: unknown placeholder {extra}: {t}")
        if "'" in t: bad.append(f"{k}: straight apostrophe: {t}")
        if s["tone"]=="serious" and x["f"]: bad.append(f"{k}: serious slot marked funny")
    f=sum(1 for x in v if x["f"])
    if s["tone"]=="light" and not (20<=f<=40): bad.append(f"{k}: light slot has {f} funny")
    if s["tone"]=="playful" and not (50<=f<=70): bad.append(f"{k}: playful slot has {f} funny")
print("\n".join(bad[:60]) if bad else "OK")
