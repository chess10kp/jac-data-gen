#!/usr/bin/env python3
"""Dedup/contamination check for `native` agent tasks against the eval sets.

The agent-task pool feeds SFT, so it must not reuse eval scenarios. For every
task we compare its request.md (+ provenance title/domain) with every eval
prompt under evals/ (jac_native prompts + design-card domains from
docs/JAC_NATIVE_EVAL_V0_PLAN.md, function/v1 prompts, frontend/v1 specs):

  * domain clash: the task's title/domain mentions a reserved eval domain term
  * word 5-gram containment: |grams(task) & grams(eval)| / |grams(task)|
  * word 8-gram exact overlap count (any shared 8-gram is a red flag)
  * the same metrics task-vs-task inside the pool (near-duplicate tasks)

A task is clean iff no domain clash, max containment < 0.10 and no shared 8-gram.
"""
from __future__ import annotations

import json
import re
import sys
from functools import lru_cache
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]

# Domains of the jac_native v0 eval (incl. the planned design cards) and the
# frontend eval apps. Task titles/domains must avoid these.
RESERVED_DOMAINS = [
    "capacity alloc", "allocat", "sensor", "reachability", "service call", "follower",
    "recommendation", "todo", "to-do", "habit", "kanban", "expense", "storefront",
    "e-commerce", "notes app", "quiz", "pomodoro", "chat", "spreadsheet", "checkers",
    "counter", "color picker", "markdown", "form wizard", "dashboard", "canvas drawing",
    "step-sequencer", "sequencer", "video player", "notion", "figma",
]
CONTAIN_MAX = 0.10
WORD = re.compile(r"[a-z0-9_]+")


def words(s: str) -> list[str]:
    return WORD.findall(s.lower())


def grams(ws: list[str], n: int) -> set[tuple[str, ...]]:
    return {tuple(ws[i:i + n]) for i in range(len(ws) - n + 1)}


@lru_cache(maxsize=1)
def eval_corpus() -> list[tuple[str, list[str]]]:
    docs: list[tuple[str, str]] = []
    for p in (REPO / "evals").rglob("prompt.md"):
        docs.append((str(p.relative_to(REPO)), p.read_text()))
    plan = REPO / "docs" / "JAC_NATIVE_EVAL_V0_PLAN.md"
    if plan.exists():
        txt = plan.read_text()
        m = re.search(r"## 6\. First four task design cards(.*?)## 7\.", txt, re.S)
        if m:
            docs.append(("docs/JAC_NATIVE_EVAL_V0_PLAN.md#design-cards", m.group(1)))
    for p in (REPO / "evals" / "function").rglob("*.jsonl"):
        if "/public/" not in str(p):
            continue
        for line in p.read_text().splitlines():
            r = json.loads(line)
            docs.append((f"{p.relative_to(REPO)}:{r['id']}", r.get("prompt", "")))
    spec = REPO / "evals" / "frontend" / "v1" / "specs.json"
    if spec.exists():
        for r in json.loads(spec.read_text()):
            docs.append((f"frontend:{r['id']}", f"{r['name']} {r['spec']} {' '.join(map(str, r.get('assertions', [])))}"))
    return [(k, words(v)) for k, v in docs]


def task_text(t: Path) -> tuple[str, str]:
    meta = json.loads((t / "task.json").read_text())
    prov = meta.get("provenance", {})
    title = f"{prov.get('title', '')} {prov.get('domain', '')}"
    return title, (t / "request.md").read_text()


def score(tw: list[str], ew: list[str]) -> tuple[float, int]:
    g5 = grams(tw, 5)
    if not g5:
        return 0.0, 0
    c = len(g5 & grams(ew, 5)) / len(g5)
    o8 = len(grams(tw, 8) & grams(ew, 8))
    return c, o8


def dedup_all(tasks: list[Path]) -> dict[str, dict]:
    corpus = eval_corpus()
    texts = {t.name: task_text(t) for t in tasks}
    out: dict[str, dict] = {}
    for t in tasks:
        title, req = texts[t.name]
        tw = words(req)
        clash = [d for d in RESERVED_DOMAINS if d in title.lower()]
        best = (0.0, 0, "")
        for k, ew in corpus:
            c, o8 = score(tw, ew)
            if (c, o8) > best[:2]:
                best = (c, o8, k)
        peer = (0.0, 0, "")
        for other in tasks:
            if other.name == t.name:
                continue
            c, o8 = score(tw, words(texts[other.name][1]))
            if (c, o8) > peer[:2]:
                peer = (c, o8, other.name)
        reasons = []
        if clash:
            reasons.append(f"reserved eval domain {clash}")
        if best[0] >= CONTAIN_MAX or best[1] > 0:
            reasons.append(f"eval overlap {best[2]} c5={best[0]:.3f} o8={best[1]}")
        if peer[0] >= 0.25:
            reasons.append(f"near-duplicate task {peer[2]} c5={peer[0]:.3f}")
        out[t.name] = {
            "clean": not reasons, "reason": "; ".join(reasons),
            "eval_max_c5": round(best[0], 4), "eval_max_o8": best[1], "eval_nearest": best[2],
            "peer_max_c5": round(peer[0], 4), "peer_nearest": peer[2], "n_eval_docs": len(corpus),
        }
    return out


if __name__ == "__main__":
    root = REPO / "data" / "agent_tasks" / "native"
    res = dedup_all(sorted(p for p in root.iterdir() if (p / "task.json").exists()))
    for k, v in res.items():
        print(k, json.dumps(v))
    sys.exit(0 if all(v["clean"] for v in res.values()) else 1)
