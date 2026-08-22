#!/usr/bin/env python3
"""Cursor-agent idiomize driver for the floorfix rescue (replaces dead zen-free path).

The free opencode gateway returns all-empty since ~01:30 (ok frozen at 377), so
this mirrors farm_composer_batch.py's cursor-agent invocation but the task is the
idiomize_seam prompt: rewrite mechanical py2jac floors into idiomatic Jac.

Work records: data/floorfix/work/<id>.json {"floor_fn","python","entrypoint"}.
Output contract (drop-in for floorfix.py guard/merge):
  data/floorfix/candidates.jsonl {"id": int, "candidate": jac, "model": "...", "dt": ...}
Resume-safe: ids with a non-null latest candidate are skipped; --retry-empty also
redoes null candidates. Every record carries ===ID <id>=== framing so one batch
yields many candidates, parsed like farm's _BLOCK/_FENCE.
"""
from __future__ import annotations
import argparse, atexit, json, os, re, signal, subprocess, sys, threading, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parent))
from idiomize_seam import system_prompt, _user  # noqa: E402
from generation_ledger import new_run, record_call  # noqa: E402
from generation_ledger import summary as ledger_summary  # noqa: E402

WORK = HERE.parent / "data/floorfix/work"
CAND = HERE.parent / "data/floorfix/candidates.jsonl"
WS = "/tmp/cursor_ws"

_BLOCK = re.compile(r"===ID\s+(\S+?)===\s*(.*?)(?=(?:===ID\s+\S+?===)|\Z)", re.S)
_FENCE = re.compile(r"```(?:jac)?\s*\n(.*?)```", re.S)

_LIVE_PGIDS: set[int] = set()
_LOCK = threading.Lock()
_USAGE = {"in": 0, "out": 0, "cache": 0}

BATCH_FRAME = (
    "\n\nFor EACH record below, output EXACTLY in order:\n"
    "===ID <id>===\n```jac\n<the idiomatic function ONLY>\n```\n"
    "One block per record, same order, ids verbatim. No prose between blocks.\n")


def build_batch_prompt(recs: list[dict]) -> str:
    parts = [system_prompt(), BATCH_FRAME]
    for r in recs:
        parts.append(f"\n===ID {r['id']}===\n"
                     + _user(r["floor_fn"], r["python"], r["entrypoint"]) + "\n")
    return "".join(parts)


def parse_result(text: str) -> dict[str, str]:
    out = {}
    for m in _BLOCK.finditer(text or ""):
        fm = _FENCE.search(m.group(2))
        if fm:
            out[m.group(1)] = fm.group(1).strip()
    return out


def call_agent(recs: list[dict], model: str, timeout: int, run_id: str) -> dict[str, str]:
    t0 = time.perf_counter()
    rids = [str(r["id"]) for r in recs]
    batch_name = f"{rids[0]}..{rids[-1]}"
    argv = ["cursor-agent", "--print", "--output-format", "json", "--mode", "ask",
            "--trust", "--model", model, "--workspace", WS, build_batch_prompt(recs)]
    env = {**os.environ, "TMPDIR": "/tmp/cursor_tmp"}
    # cursor backend intermittently 429s (resource_exhausted -> rc=1, empty
    # stdout, retries inside the CLI exhausted). Retry the whole call with
    # backoff before recording a failure.
    out, d = "", None
    for attempt in range(4):
        p = subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                             text=True, start_new_session=True, env=env)
        pgid = os.getpgid(p.pid)
        with _LOCK:
            _LIVE_PGIDS.add(pgid)
        try:
            out, _ = p.communicate(timeout=timeout)
        except subprocess.TimeoutExpired:
            _kill_pg(pgid)
            try: p.communicate(timeout=10)
            except Exception: pass  # noqa: E701
            record_call(run_id, pipeline="floorfix-cursor", batch=batch_name, model=model,
                        status="timeout", record_ids=rids,
                        error=f"timeout after {timeout}s (attempt {attempt})",
                        dur_s=time.perf_counter() - t0)
            out = ""
        finally:
            with _LOCK:
                _LIVE_PGIDS.discard(pgid)
        if out.strip():
            try:
                d = json.loads(out)
                break
            except Exception:  # noqa: BLE001
                d = None
        if attempt < 3:
            time.sleep(25 * (attempt + 1))   # backoff for resource_exhausted
    if d is None:
        record_call(run_id, pipeline="floorfix-cursor", batch=batch_name, model=model,
                    status="parse_error", record_ids=rids,
                    error=f"empty/bad output after retries: {(out or '')[:200]}",
                    dur_s=time.perf_counter() - t0)
        return {}
    u = d.get("usage") or {}
    with _LOCK:
        _USAGE["in"] += u.get("inputTokens", 0); _USAGE["out"] += u.get("outputTokens", 0)
        _USAGE["cache"] += u.get("cacheReadTokens", 0)
    res = parse_result(d.get("result", ""))
    record_call(run_id, pipeline="floorfix-cursor", batch=batch_name, model=model,
                status="is_error" if d.get("is_error") else "ok", usage=u,
                record_ids=rids, n_parsed=len(res),
                error=str(d.get("error") or "")[:400] if d.get("is_error") else None,
                dur_s=time.perf_counter() - t0,
                request_id=d.get("requestId") or d.get("request_id"),
                session_id=d.get("sessionId") or d.get("session_id"))
    return res


def _kill_pg(pgid: int) -> None:
    try: os.killpg(pgid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError): pass  # noqa: E701


def canary_ok(model: str) -> bool:
    """Tiny probe call: True iff cursor backend answers (quota window open).
    resource_exhausted -> rc=1 + empty stdout, so any parseable JSON = open."""
    try:
        env = {**os.environ, "TMPDIR": "/tmp/cursor_tmp"}
        p = subprocess.run(["cursor-agent", "--print", "--output-format", "json",
                            "--mode", "ask", "--trust", "--model", model,
                            "--workspace", WS, "Reply with exactly: ok"],
                           capture_output=True, text=True, env=env, timeout=120)
        d = json.loads(p.stdout)
        return not d.get("is_error")
    except Exception:  # noqa: BLE001
        return False


_DISABLED_MCPS: list[str] = []


def _mcp_list() -> list[str]:
    try:
        out = subprocess.run(["cursor-agent", "mcp", "list"], capture_output=True,
                             text=True, timeout=30).stdout
        return [ln.split(":")[0].strip() for ln in out.splitlines() if ":" in ln]
    except Exception:  # noqa: BLE001
        return []


def _mcp_disable_all():
    for name in _mcp_list():
        r = subprocess.run(["cursor-agent", "mcp", "disable", name],
                           capture_output=True, text=True, timeout=30)
        if r.returncode == 0:
            _DISABLED_MCPS.append(name)
    if _DISABLED_MCPS:
        print(f"MCP disabled for run: {_DISABLED_MCPS}", flush=True)


def _mcp_reenable():
    for name in list(_DISABLED_MCPS):
        subprocess.run(["cursor-agent", "mcp", "enable", name],
                       capture_output=True, text=True, timeout=30)
        _DISABLED_MCPS.remove(name)


def _sweep():
    with _LOCK:
        pgids = list(_LIVE_PGIDS)
    for g in pgids:
        _kill_pg(g)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default="auto")
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--timeout", type=int, default=360)
    ap.add_argument("--batch", type=int, default=10)
    ap.add_argument("--retry-empty", action="store_true",
                    help="also redo records whose latest candidate is null")
    args = ap.parse_args()

    os.makedirs(WS, exist_ok=True); os.makedirs("/tmp/cursor_tmp", exist_ok=True)
    atexit.register(_mcp_reenable); atexit.register(_sweep)
    for s in (signal.SIGINT, signal.SIGTERM):
        signal.signal(s, lambda *_: (_sweep(), _mcp_reenable(), sys.exit(1)))

    # todo = work ids with no candidate (or null, when --retry-empty)
    latest: dict[int, dict] = {}
    if CAND.exists():
        for ln in CAND.read_text().splitlines():
            if ln.strip():
                try: d = json.loads(ln)
                except Exception: continue  # noqa: E722
                latest[d["id"]] = d
    todo = []
    for p in sorted(WORK.glob("*.json"), key=lambda p: int(p.stem)):
        rid = int(p.stem)
        c = latest.get(rid)
        if c is None or (args.retry_empty and not c.get("candidate")):
            todo.append(json.loads(p.read_text()) | {"id": rid})
    print(f"floorfix cursor-agent: {len(todo)} records (of {len(latest)} cand'd), "
          f"model={args.model}, {args.workers} workers, batch={args.batch}, MCP off",
          flush=True)
    if not todo:
        return 0

    run_id = new_run("floorfix-cursor", model=args.model)
    _mcp_disable_all()

    batches = [todo[i:i + args.batch] for i in range(0, len(todo), args.batch)]
    fh = CAND.open("a")
    t0, wrote = time.perf_counter(), 0
    n_batches = len(batches)
    attempts: dict[int, int] = {}          # id(batch) -> failed waves
    try:
        # canary-gated waves: probe quota with a tiny call, then unleash a
        # small wave; re-probe between waves. resource_exhausted windows can
        # stay shut for long stretches, so blind retrying wastes hours.
        wave_size = max(2, args.workers * 2)
        pending = list(batches)
        waves = 0
        while pending:
            waves += 1
            waited = 0
            while not canary_ok(args.model):
                if waited == 0:
                    print(f"[canary] quota window shut — probing every 120s",
                          flush=True)
                time.sleep(120); waited += 120
            if waited:
                print(f"[canary] window open after {waited}s — resuming", flush=True)
            chunk, pending = pending[:wave_size], pending[wave_size:]
            failed = []
            with ThreadPoolExecutor(max_workers=args.workers) as ex:
                futs = {ex.submit(call_agent, b, args.model, args.timeout, run_id): b
                        for b in chunk}
                for fut in as_completed(futs):
                    recs = futs[fut]
                    cands = fut.result()
                    for r in recs:
                        c = cands.get(str(r["id"]))
                        if c:
                            wrote += 1
                            fh.write(json.dumps({"id": r["id"], "candidate": c,
                                                 "model": f"cursor-{args.model}",
                                                 "dt": 0}) + "\n")
                    fh.flush()
                    if not cands:
                        attempts[id(recs)] = attempts.get(id(recs), 0) + 1
                        if attempts[id(recs)] < 8:
                            failed.append(recs)
            pending = pending + failed
            done = n_batches - len({id(b) for b in pending})
            with _LOCK:
                u = dict(_USAGE)
            print(f"  [wave {waves}] {time.perf_counter()-t0:.0f}s wrote={wrote} "
                  f"pending={len(pending)}"
                  f" | usage in={u['in']:,} out={u['out']:,} cache={u['cache']:,}",
                  flush=True)
    finally:
        fh.close()
    print(f"done: wrote {wrote}, {time.perf_counter()-t0:.0f}s", flush=True)
    print(ledger_summary(run_id), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
