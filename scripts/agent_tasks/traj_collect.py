#!/usr/bin/env python3
"""Merge fetched `traj` CI artifacts into SFT trajectories + stats (local, light).

    training/.venv/bin/python scripts/agent_tasks/traj_collect.py runs/ci/traj/<run_id> [more run dirs...] \
        [--out data/trajectories/glm] [--no-tokens]

Per session (one `<sid>.jsonl` under */sessions/): JacCoder's pi converter
(script/dataset/trajectory/pi.py) turns it into trajectories; each gets
meta.task = {task_id, kind, level, sample, sid}, meta.grade = {passed, failed_gates},
meta.run = {wall_s, n_tool_calls, rc, timed_out, attempt}. Later run dirs win
for a sid seen twice. Writes <out>/all.jsonl, <out>/passed.jsonl (graded pass),
<out>/stats.json (+ the converter's all.stats.json / passed.stats.json).

Token lengths are measured through the Ornith chat template (local tokenizer
ornith-ai/Ornith-1.5-9B from the HF cache; run with training/.venv python and
HF_HUB_OFFLINE=1).
"""
from __future__ import annotations

import argparse
import json
import os
import re
import statistics
import sys
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
JACCODER = Path(os.environ.get("JACCODER", Path.home() / "repos" / "JacCoder"))
sys.path.insert(0, str(JACCODER / "script"))
from dataset.trajectory import pi as pi_conv  # noqa: E402
from dataset.trajectory.common import to_template_input, write_trajectories  # noqa: E402

CHECK_ERR = re.compile(r"error\[E\d{4}\]|jac check: \d+ new errors?|\bE\d{4}\b.*(error|Error)|^Error", re.M)
ENV_DEBUG = re.compile(r"~/\.cache|\$HOME/\.cache|/\.cache/|(^|[\s;&|(])ps(\s|$)|pgrep|pkill|postgres|pg_\w+|"
                       r"/proc/|JAC_CACHE_HOME|\bss -|netstat|lsof")
ESCAPE = re.compile(r"(^|[\s'\"=])\.\./|agent_tasks|grader|/home/runner/work|\bsudo\b|\bcd\s+(/|~)(?!\S*/ws/)")
TOKEN_MODEL = "ornith-ai/Ornith-1.5-9B"


def jl(p: Path) -> list[dict]:
    return [json.loads(x) for x in p.read_text().splitlines() if x.strip()] if p.exists() else []


def gather(run_dirs: list[Path]) -> tuple[dict, dict, dict]:
    """sid -> session path / run row / grade row (later dirs override earlier)."""
    sess, runs, grades = {}, {}, {}
    for rd in run_dirs:
        for shard in sorted(p for p in rd.rglob("runs.jsonl")):
            base = shard.parent
            for r in jl(base / "runs.jsonl"):
                runs[r["sid"]] = r
            for g in jl(base / "grades.jsonl"):
                grades[g["sid"]] = g
            for fp in (base / "sessions").glob("*.jsonl"):
                if ".failed" not in fp.stem:
                    sess[fp.stem] = fp
    return sess, runs, grades


def calls_with_results(rows: list[dict]) -> list[tuple[dict, dict | None]]:
    """(tool_call row, its tool_result row) in order (results pair with calls by order per response)."""
    out, pending = [], []
    for r in rows:
        if r["role"] == "assistant" and r["mode"] == "tool_call":
            pending.append(r)
            out.append([r, None])
        elif r["mode"] == "tool_result":
            for pair in out:
                if pair[1] is None:
                    pair[1] = r
                    break
    return [tuple(p) for p in out]


def behavior(traj: dict) -> dict:
    pairs = calls_with_results(traj["rows"])
    guide, guide_after_err, env_dbg, escape, blocked = 0, 0, 0, 0, 0
    env_cmds, esc_cmds = [], []
    prev_res = None
    for call, res in pairs:
        cmd = str(call["args"].get("command", "")) if call["name"] == "bash" else ""
        paths = " ".join(str(call["args"].get(k, "")) for k in ("path", "root", "file_path"))
        if "jac guide" in cmd:
            guide += 1
            if prev_res is not None and CHECK_ERR.search(prev_res.get("content", "")):
                guide_after_err += 1
        if cmd and ENV_DEBUG.search(cmd):
            env_dbg += 1
            env_cmds.append(cmd[:160])
        if ESCAPE.search(cmd) or ESCAPE.search(paths) or re.search(r"(^|\s)/(?!tmp)", paths):
            escape += 1
            esc_cmds.append((cmd or paths)[:160])
        if res is not None and "is disabled. Use jac_ast_search" in res.get("content", ""):
            blocked += 1
        prev_res = res
    return {"tool_calls": len(pairs), "guide_lookups": guide, "guide_after_check_error": guide_after_err,
            "env_debug_calls": env_dbg, "env_debug_cmds": env_cmds[:5], "escape_suspect_calls": escape,
            "escape_cmds": esc_cmds[:5], "shell_search_blocked": blocked,
            "loop_masked_responses": sum(1 for r in traj["rows"] if r.get("masked") == "loop" and r["mode"] != "think"),
            "tools": dict(Counter(c["name"] for c, _ in pairs))}


def token_lengths(trajs: list[dict]) -> list[int | None]:
    try:
        os.environ.setdefault("HF_HUB_OFFLINE", "1")
        from transformers import AutoTokenizer
        tok = AutoTokenizer.from_pretrained(TOKEN_MODEL)
    except Exception as e:
        print(f"tokenizer unavailable ({e}); skipping token lengths", file=sys.stderr)
        return [None] * len(trajs)
    out = []
    for t in trajs:
        msgs = to_template_input(t, None)
        for m in msgs:
            m.pop("weight", None)
        try:
            ids = tok.apply_chat_template(msgs, tools=t.get("tools"), tokenize=True)
            out.append(len(ids["input_ids"] if isinstance(ids, dict) else ids))
        except Exception as e:
            print(f"template failed for {t['meta'].get('task', {}).get('sid')}: {e}", file=sys.stderr)
            out.append(None)
    return out


def dist(xs: list) -> dict:
    xs = sorted(x for x in xs if x is not None)
    if not xs:
        return {}
    q = lambda f: xs[min(len(xs) - 1, int(f * len(xs)))]  # noqa: E731
    return {"n": len(xs), "mean": round(statistics.mean(xs), 1), "p10": q(.1), "p50": q(.5), "p90": q(.9), "max": xs[-1]}


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("run_dirs", nargs="+", type=Path)
    ap.add_argument("--out", type=Path, default=REPO / "data" / "trajectories" / "glm")
    ap.add_argument("--no-tokens", action="store_true")
    a = ap.parse_args()

    sess, runs, grades = gather(a.run_dirs)
    trajs, counts, per_session = [], Counter(), []
    for sid in sorted(set(sess) | set(runs)):
        run, g = runs.get(sid, {}), grades.get(sid, {})
        ts = pi_conv.convert_file(sess[sid], counts, False) if sid in sess else []
        counts["sessions"] += 1
        task = {"task_id": run.get("task_id", sid.split("__")[0]), "kind": run.get("kind"),
                "level": run.get("level"), "sample": run.get("sample"), "sid": sid}
        grade = {"passed": bool(g.get("passed")), "failed_gates": g.get("failed_gates", []),
                 "gates": {k: bool(v.get("ok")) for k, v in g.get("gates", {}).items()}}
        rmeta = {k: run.get(k) for k in ("wall_s", "n_tool_calls", "rc", "timed_out", "attempt", "model",
                                        "rate_limit_events", "final_stop", "sandbox")}
        beh = None
        for t in ts:
            t["meta"].update(task=task, grade=grade, run=rmeta)
            t["meta"]["behavior"] = beh = behavior(t)
            trajs.append(t)
        per_session.append({**task, "passed": grade["passed"], "failed_gates": grade["failed_gates"],
                            "n_trajs": len(ts), **{k: rmeta[k] for k in ("wall_s", "n_tool_calls", "timed_out",
                                                                         "rate_limit_events", "final_stop")},
                            **(beh or {})})

    toks = [None] * len(trajs) if a.no_tokens else token_lengths(trajs)
    for t, n in zip(trajs, toks):
        t["meta"]["tokens_ornith"] = n
    a.out.mkdir(parents=True, exist_ok=True)
    write_trajectories(trajs, a.out / "all.jsonl", dict(counts))
    passed = [t for t in trajs if t["meta"]["grade"]["passed"]]
    write_trajectories(passed, a.out / "passed.jsonl")
    with (a.out / "sessions.jsonl").open("w") as f:
        for r in per_session:
            f.write(json.dumps(r) + "\n")

    by = defaultdict(lambda: [0, 0])
    for r in per_session:
        for key in (f"kind={r['kind']}", f"kind={r['kind']} L{r['level']}", f"level=L{r['level']}", "all"):
            by[key][0] += r["passed"]
            by[key][1] += 1
    st = {
        "sessions": len(per_session), "trajectories": len(trajs), "passed_trajectories": len(passed),
        "pass_rate": {k: f"{p}/{n} ({100 * p / n:.0f}%)" for k, (p, n) in sorted(by.items())},
        "timed_out": sum(bool(r["timed_out"]) for r in per_session),
        "api_error_final": sum(r["final_stop"] in ("error", "aborted") for r in per_session),
        "rate_limit_events": sum(r["rate_limit_events"] or 0 for r in per_session),
        "tool_calls": dist([r["n_tool_calls"] for r in per_session]),
        "wall_s": dist([r["wall_s"] for r in per_session]),
        "guide_lookups_per_session": dist([r.get("guide_lookups") for r in per_session]),
        "sessions_with_guide": sum((r.get("guide_lookups") or 0) > 0 for r in per_session),
        "guide_lookups_total": sum(r.get("guide_lookups") or 0 for r in per_session),
        "guide_lookups_after_check_error": sum(r.get("guide_after_check_error") or 0 for r in per_session),
        "sessions_env_debug": sum((r.get("env_debug_calls") or 0) > 0 for r in per_session),
        "sessions_escape_suspect": sum((r.get("escape_suspect_calls") or 0) > 0 for r in per_session),
        "sessions_shell_search_blocked": sum((r.get("shell_search_blocked") or 0) > 0 for r in per_session),
        "sessions_with_loop_masking": sum((r.get("loop_masked_responses") or 0) > 0 for r in per_session),
        "failed_gates": dict(Counter(g for r in per_session for g in r["failed_gates"])),
        "tokens_ornith_all": dist(toks),
        "tokens_ornith_passed": dist([t["meta"]["tokens_ornith"] for t in passed]),
        "tokens_over_32k": sum(1 for x in toks if x and x > 32768),
        "tokens_over_64k": sum(1 for x in toks if x and x > 65536),
        "converter": dict(counts),
    }
    (a.out / "stats.json").write_text(json.dumps(st, indent=1) + "\n")
    print(json.dumps(st, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main())
