#!/usr/bin/env python3
"""Shared cursor-agent composer driver for the js2jac / FARM dataset pipelines.

Extracts the boilerplate that used to be copy-pasted between
scripts/js2jac_dataset/js2jac_composer_batch.py and farm_composer_batch.py,
and upgrades it to the resilience standard of the py2jac pipeline
(scripts/gen): every model call is durably ledgered, output appends are
fsync'd, batch-file shrinks are atomic, and transient failures (timeout /
unparseable stream / empty parse) are retried with exponential backoff
instead of silently dropping the batch.

Pipeline-specific code stays in the callers:
  - build_prompt(recs) -> str            full user prompt for a batch
  - parse_result(text) -> {id: jac}      extract candidates from the reply
  - sysprompt_for(recs) -> str | None    optional per-batch system-prompt pick

Output contract is unchanged: {"id", "candidate"} JSONL appended to --out,
resumable by id (done ids are never re-bought; partially-done batch files are
shrunk atomically so a restart re-runs only the missing records).
"""
from __future__ import annotations
import argparse, atexit, json, os, signal, subprocess, sys, threading, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Callable

sys.path.insert(0, str(Path(__file__).resolve().parent))
import jsonl_io
from generation_ledger import new_run, record_call, summary as ledger_summary

_LIVE_PGIDS: set[int] = set()
_LOCK = threading.Lock()
_DISABLED_MCPS: list[str] = []


# ---- process-group hygiene ------------------------------------------------ #
def _kill_pg(pgid: int) -> None:
    try:
        os.killpg(pgid, signal.SIGKILL)
    except (ProcessLookupError, PermissionError):
        pass


def _sweep() -> None:
    """Kill only cursor-agent trees spawned by this driver (tracked PGIDs)."""
    with _LOCK:
        pgids = list(_LIVE_PGIDS)
    for g in pgids:
        _kill_pg(g)


def _mcp_list() -> list[str]:
    try:
        out = subprocess.run(["cursor-agent", "mcp", "list"], capture_output=True,
                             text=True, timeout=30).stdout
        return [ln.split(":")[0].strip() for ln in out.splitlines() if ":" in ln]
    except Exception:  # noqa: BLE001
        return []


def _mcp_disable_all() -> None:
    for name in _mcp_list():
        r = subprocess.run(["cursor-agent", "mcp", "disable", name],
                           capture_output=True, text=True, timeout=30)
        if r.returncode == 0:
            _DISABLED_MCPS.append(name)
    if _DISABLED_MCPS:
        print(f"MCP disabled for run: {_DISABLED_MCPS}", flush=True)


def _mcp_reenable() -> None:
    for name in list(_DISABLED_MCPS):
        subprocess.run(["cursor-agent", "mcp", "enable", name],
                       capture_output=True, text=True, timeout=30)
        _DISABLED_MCPS.remove(name)


def install_signal_handlers() -> None:
    """Sweep child process groups + restore MCP on Ctrl-C / TERM."""
    atexit.register(_mcp_reenable)
    atexit.register(_sweep)
    for s in (signal.SIGINT, signal.SIGTERM):
        signal.signal(s, lambda *_: (_sweep(), _mcp_reenable(), sys.exit(1)))


# ---- one cursor-agent invocation ------------------------------------------ #
def _invoke(prompt: str, model: str, workspace: str, tmpdir: str,
            timeout: int) -> tuple[dict | None, str | None]:
    """Run cursor-agent once. Returns (payload_dict, None) or (None, err_kind)
    where err_kind is 'spawn' | 'timeout' | 'parse_error'."""
    argv = ["cursor-agent", "--print", "--output-format", "json", "--mode", "ask",
            "--trust", "--model", model, "--workspace", workspace, prompt]
    env = {**os.environ, "TMPDIR": tmpdir}
    try:
        p = subprocess.Popen(argv, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                             text=True, start_new_session=True, env=env)
    except OSError as e:
        print(f"[composer] spawn failed: {e}", flush=True)
        return None, "spawn"
    pgid = os.getpgid(p.pid)
    with _LOCK:
        _LIVE_PGIDS.add(pgid)
    try:
        out, _ = p.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        _kill_pg(pgid)
        try:
            p.communicate(timeout=10)
        except Exception:  # noqa: BLE001
            pass
        return None, "timeout"
    finally:
        with _LOCK:
            _LIVE_PGIDS.discard(pgid)
    try:
        return json.loads(out), None
    except Exception:  # noqa: BLE001
        return None, "parse_error"


# Transient = worth a retry with backoff: gateway hiccup, cut stream, OOM-killed
# child. Mirrors idiomize_seam.zen_idiomize's 429/5xx policy (commit 826ecc7a).
_TRANSIENT = {"timeout", "parse_error"}


def call_agent(batch_file: str, *, pipeline: str, model: str, run_id: str,
               timeout: int, workspace: str, tmpdir: str,
               build_prompt: Callable[[list[dict]], str],
               parse_result: Callable[[str], dict[str, str]],
               sysprompt_for: Callable[[list[dict]], str] | None = None,
               max_attempts: int = 3, backoff_s: float = 5.0,
               ) -> tuple[dict[str, str], dict[str, int]]:
    """Compose one batch with retry-on-transient. Returns ({id: candidate}, usage).

    Every attempt is ledgered (ok / is_error / parse_error / timeout / spawn /
    empty) so no spend is lost even if this process dies mid-run. Retries only
    when NOTHING usable came back and the failure looks transient; a reply that
    parsed to >=1 record is accepted as-is.
    """
    recs = json.loads(Path(batch_file).read_text())
    t0 = time.perf_counter()
    rids, batch_name = [r["id"] for r in recs], Path(batch_file).name
    body = build_prompt(recs)
    sysprompt = sysprompt_for(recs) if sysprompt_for else ""
    prompt = (sysprompt + "\n\n" + body) if sysprompt else body

    usage_total: dict[str, int] = {}
    last_err = ""
    for attempt in range(max_attempts):
        d, err = _invoke(prompt, model, workspace, tmpdir, timeout)
        if err == "spawn":
            record_call(run_id, pipeline=pipeline, status="spawn_error",
                        batch=batch_name, model=model, record_ids=rids,
                        error="cursor-agent spawn failed")
            return {}, usage_total  # not transient — fail fast
        if err in _TRANSIENT:
            last_err = f"{err} after {timeout}s" if err == "timeout" else "unparseable stream"
            record_call(run_id, pipeline=pipeline, status=err, batch=batch_name,
                        model=model, record_ids=rids, error=last_err,
                        dur_s=time.perf_counter() - t0)
            if attempt < max_attempts - 1:
                time.sleep(backoff_s * (2 ** attempt))
            continue
        u = d.get("usage") or {}
        for k in ("inputTokens", "outputTokens", "cacheReadTokens"):
            usage_total[k] = usage_total.get(k, 0) + int(u.get(k) or 0)
        res = {} if d.get("is_error") else parse_result(d.get("result", ""))
        # drop IDs the model hallucinated / bled over from another batch —
        # only records this batch asked about may enter the output stream
        allowed = set(rids)
        foreign = [r for r in res if r not in allowed]
        if foreign:
            res = {r: c for r, c in res.items() if r in allowed}
            print(f"[composer] {batch_name}: dropped {len(foreign)} foreign "
                  f"ids from reply ({', '.join(foreign[:3])}...)", flush=True)
        status = ("is_error" if d.get("is_error")
                  else "ok" if res else "empty")
        record_call(run_id, pipeline=pipeline, batch=batch_name, model=model,
                    status=status, usage=u, record_ids=rids, n_parsed=len(res),
                    error=(str(d.get("error"))[:400] if d.get("is_error")
                           else "no records parsed from reply" if not res else None),
                    dur_s=time.perf_counter() - t0,
                    request_id=d.get("requestId") or d.get("request_id"),
                    session_id=d.get("sessionId") or d.get("session_id"))
        if res or not _is_retryable_empty(d):
            return res, usage_total
        last_err = "empty parse"
        if attempt < max_attempts - 1:
            time.sleep(backoff_s * (2 ** attempt))
    print(f"[composer] {batch_name}: giving up after {max_attempts} attempts "
          f"({last_err})", flush=True)
    return {}, usage_total


def _is_retryable_empty(d: dict) -> bool:
    """An is_error reply is usually deterministic (bad prompt/model) — accept
    and move on. An empty parse of a clean reply is usually a cut stream."""
    return not d.get("is_error")


# ---- main loop ------------------------------------------------------------- #
def run_composer(pipeline: str, args: argparse.Namespace,
                 build_prompt: Callable[[list[dict]], str],
                 parse_result: Callable[[str], dict[str, str]],
                 sysprompt_for: Callable[[list[dict]], str] | None = None,
                 prefilter: Callable[[Path, set[str]], bool] | None = None,
                 ) -> int:
    """Drive all batches in args.batch_dir into args.out (JSONL, append+fsync).

    - Resume: ids present in --out are skipped; batch files containing any work
      are shrunk ATOMICALLY to the remaining records (crash-safe rewrite).
    - prefilter(batch_path, done_ids) -> False drops a batch before spending
      tokens (used by js2jac for deterministic pre-REJECT).
    - Empty batches are tallied loudly: a high empty ratio means the prompt or
      model broke, and the exit code flags it (rc=4) instead of printing green.
    """
    workspace = args.workspace
    tmpdir = os.environ.get("CURSOR_TMPDIR", "/tmp/cursor_tmp")
    if not getattr(args, "batch_dir", None) or not getattr(args, "out", None):
        raise SystemExit("composer needs --batch-dir and --out")
    os.makedirs(workspace, exist_ok=True)
    os.makedirs(tmpdir, exist_ok=True)
    install_signal_handlers()
    run_id = new_run(pipeline, model=args.model)

    out_path = Path(args.out)
    try:
        done_rows = jsonl_io.read_strict(out_path)
    except jsonl_io.CorruptLine as e:
        print(f"[composer] FATAL: {e}", flush=True)
        return 2
    done: set[str] = {r["id"] for r in done_rows}

    todo: list[Path] = []
    for bf in sorted(Path(args.batch_dir).glob("*.json")):
        recs = json.loads(bf.read_text())
        remaining = [r for r in recs if r["id"] not in done]
        if not remaining:
            continue
        if len(remaining) != len(recs):
            # atomic shrink so a crash mid-run never loses the batch manifest
            # (keep the JSON-array format call_agent expects)
            jsonl_io.atomic_write(bf, [json.dumps(remaining)])
        if prefilter and not prefilter(bf, done):
            continue
        todo.append(bf)

    print(f"{pipeline}: {len(todo)} batches (of {len(list(Path(args.batch_dir).glob('*.json')))}), "
          f"model={args.model}, {args.workers} workers, MCP off, ask-mode, "
          f"retries={args.max_attempts}", flush=True)

    stats = {"wrote": 0, "empty": 0}
    t0 = time.perf_counter()

    def work(bf: Path) -> None:
        cand, _usage = call_agent(
            str(bf), pipeline=pipeline, model=args.model, run_id=run_id,
            timeout=args.timeout, workspace=workspace, tmpdir=tmpdir,
            build_prompt=build_prompt, parse_result=parse_result,
            sysprompt_for=sysprompt_for, max_attempts=args.max_attempts)
        with _LOCK:
            for rid, code in cand.items():
                if rid in done:
                    continue
                jsonl_io.append(out_path, {"id": rid, "candidate": code})
                done.add(rid)
                stats["wrote"] += 1
            if not cand:
                stats["empty"] += 1

    try:
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            futs = [ex.submit(work, bf) for bf in todo]
            for i, fut in enumerate(as_completed(futs), 1):
                fut.result()  # surface unexpected exceptions per batch
                if i % 5 == 0 or i == len(todo):
                    el = time.perf_counter() - t0
                    print(f"  [{i}/{len(todo)}] {el:.0f}s  wrote {stats['wrote']}  "
                          f"empty {stats['empty']}", flush=True)
    finally:
        _sweep()
        _mcp_reenable()

    empty_ratio = stats["empty"] / len(todo) if todo else 0.0
    print(f"done: wrote {stats['wrote']}, empty {stats['empty']} "
          f"({empty_ratio:.0%}), {time.perf_counter() - t0:.0f}s | "
          f"durable totals in ledger:", flush=True)
    print(ledger_summary(run_id), flush=True)
    if todo and empty_ratio > 0.5:
        print(f"[composer] ALERT: {stats['empty']}/{len(todo)} batches produced "
              f"nothing — inspect ledger run {run_id} before re-running.", flush=True)
        return 4
    return 0


def add_common_args(ap: argparse.ArgumentParser) -> None:
    ap.add_argument("--batch-dir")
    ap.add_argument("--out")
    ap.add_argument("--model", default="composer-2.5")
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--timeout", type=int, default=360)
    ap.add_argument("--workspace", default=os.environ.get("CURSOR_WS", "/tmp/cursor_ws"))
    ap.add_argument("--max-attempts", type=int, default=3,
                    help="retries for transient failures (timeout/cut stream)")
