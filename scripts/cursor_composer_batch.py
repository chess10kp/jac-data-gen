#!/usr/bin/env python3
"""Batched composer idiomize via cursor-agent — read-only, MCP-stripped, isolated.

One cursor-agent call idiomizes a whole batch (10 records), amortizing the
agent's fixed per-call context ~10x. Runs in `--mode ask` (read-only Q&A: no
shell, no writes -> no disk pollution) with `--output-format json` (structured
result + real token usage). Global MCP config is moved aside for the whole run
(restored via atexit) so no MCP servers load; an empty trusted workspace keeps
this repo's .cursor rules/skills out of context. cursor-agent runs in its own
process group so the whole tree is killable on timeout/teardown.

Output contract matches the Claude workflow: {id, candidate} JSONL for the guard.
"""
from __future__ import annotations
import argparse, atexit, json, os, re, signal, subprocess, sys, threading, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).resolve().parent))
from idiomize_seam import system_prompt
from generation_ledger import new_run, record_call
from generation_ledger import summary as ledger_summary

# MCP is stripped externally via `cursor-agent mcp disable <id>` (see the launch
# wrapper) — the safe, reversible mechanism. This driver does NOT touch config
# files; it only guarantees process-tree teardown.
WS = "/tmp/cursor_ws"

_BLOCK = re.compile(r"===ID\s+(\d+)===\s*(.*?)(?=(?:===ID\s+\d+===)|\Z)", re.S)
_FENCE = re.compile(r"```(?:jac)?\s*\n(.*?)```", re.S)
_CODE_START = re.compile(r'^\s*(def\s|glob\s|import\s|"""|\'\'\')')

_LIVE_PGIDS: set[int] = set()
_LOCK = threading.Lock()
_USAGE = {"in": 0, "out": 0, "cache": 0}


def _extract_code(seg: str) -> str | None:
    m = _FENCE.search(seg)
    if m:
        return m.group(1).strip()
    lines = seg.splitlines()
    for i, ln in enumerate(lines):
        if _CODE_START.match(ln):
            body = "\n".join(lines[i:]).strip()
            return body if re.search(r"\bdef\s+\w+\s*\(", body) else None
    return None


def parse_result(text: str) -> dict[int, str]:
    out = {}
    for m in _BLOCK.finditer(text or ""):
        code = _extract_code(m.group(2))
        if code:
            out[int(m.group(1))] = code
    return out


def build_prompt(recs: list[dict]) -> str:
    parts = ["Idiomize EACH Jac function below. Output EXACTLY this per record, in order:\n"
             "===ID <id>===\n```jac\n<idiomatic jac>\n```\n"
             "Rules: keep the entrypoint name EXACTLY; valid Jac only (braces + semicolons, "
             "never Python colons); replace Any/object with concrete types; NEVER use `any`; "
             "never backtick-escape ordinary names like list/dict/switch; no test blocks, no "
             "`with entry`, no prose. Output nothing but the ===ID/fence blocks.\n"]
    for r in recs:
        parts.append(f"\n===ID {r['id']}===  (entrypoint: {r['entrypoint']})\n"
                     f"FLOOR:\n{r['floor_fn']}\n\nPYTHON:\n{r['python'][:700]}\n")
    return "".join(parts)


def call_agent(batch_file: str, model: str, sysprompt: str, timeout: int,
               run_id: str = "-") -> dict[int, str]:
    recs = json.loads(Path(batch_file).read_text())
    t0 = time.perf_counter()
    rids, batch_name = [r["id"] for r in recs], Path(batch_file).name
    prompt = sysprompt + "\n\n" + build_prompt(recs)
    argv = ["cursor-agent", "--print", "--output-format", "json", "--mode", "ask",
            "--trust", "--model", model, "--workspace", WS, prompt]
    env = {**os.environ, "TMPDIR": "/tmp/cursor_tmp"}
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
        except Exception: pass  # noqa: BLE001,E701
        record_call(run_id, pipeline="py2jac-composer", batch=batch_name, model=model,
                    status="timeout", record_ids=rids, error=f"timeout after {timeout}s",
                    dur_s=time.perf_counter() - t0)
        return {}
    finally:
        with _LOCK:
            _LIVE_PGIDS.discard(pgid)
    try:
        d = json.loads(out)
    except Exception as e:  # noqa: BLE001
        record_call(run_id, pipeline="py2jac-composer", batch=batch_name, model=model,
                    status="parse_error", record_ids=rids,
                    error=f"{e}: {(out or '')[:300]}", dur_s=time.perf_counter() - t0)
        return {}
    u = d.get("usage") or {}
    with _LOCK:
        _USAGE["in"] += u.get("inputTokens", 0); _USAGE["out"] += u.get("outputTokens", 0)
        _USAGE["cache"] += u.get("cacheReadTokens", 0)
    res = parse_result(d.get("result", ""))
    record_call(run_id, pipeline="py2jac-composer", batch=batch_name, model=model,
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


# --- MCP strip via cursor's own reversible mechanism (no config-file moves) -- #
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
    """Kill only cursor-agent trees spawned by this driver (tracked PGIDs)."""
    with _LOCK:
        pgids = list(_LIVE_PGIDS)
    for g in pgids:
        _kill_pg(g)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--batch-dir", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--model", default="composer-2.5")
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--timeout", type=int, default=360)
    args = ap.parse_args()

    os.makedirs(WS, exist_ok=True); os.makedirs("/tmp/cursor_tmp", exist_ok=True)
    # re-enable MCP + kill our agent PGIDs on exit (normal, atexit, SIGINT/SIGTERM)
    atexit.register(_mcp_reenable); atexit.register(_sweep)
    for s in (signal.SIGINT, signal.SIGTERM):
        signal.signal(s, lambda *_: (_sweep(), _mcp_reenable(), sys.exit(1)))
    _mcp_disable_all()

    sysprompt = system_prompt()
    run_id = new_run("py2jac-composer", model=args.model)
    out_path = Path(args.out)
    done = set()
    if out_path.exists():
        for line in out_path.read_text().splitlines():
            if line.strip(): done.add(json.loads(line)["id"])
    batches = sorted(Path(args.batch_dir).glob("*.json"))
    todo = [bf for bf in batches
            if {r["id"] for r in json.loads(bf.read_text())} - done]
    print(f"batched cursor-agent: {len(todo)} batches (of {len(batches)}), "
          f"model={args.model}, {args.workers} workers, MCP off, ask-mode", flush=True)

    fh = open(out_path, "a")
    t0, wrote, empty = time.perf_counter(), 0, 0
    try:
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            futs = [ex.submit(call_agent, str(bf), args.model, sysprompt, args.timeout, run_id)
                    for bf in todo]
            for i, fut in enumerate(as_completed(futs), 1):
                cand = fut.result()
                with _LOCK:
                    for rid, code in cand.items():
                        if rid not in done:
                            fh.write(json.dumps({"id": rid, "candidate": code}) + "\n")
                            done.add(rid); wrote += 1
                    fh.flush()
                    if not cand: empty += 1
                if i % 5 == 0:
                    tok = _USAGE
                    per = (tok["in"] + tok["out"]) / max(1, wrote)
                    print(f"  [{i}/{len(todo)}] {time.perf_counter()-t0:.0f}s  wrote {wrote}  "
                          f"empty {empty}  ~{per:.0f} tok/record (in {tok['in']} out {tok['out']})",
                          flush=True)
    finally:
        fh.close(); _sweep(); _mcp_reenable()
    tok = _USAGE
    print(f"done: wrote {wrote}, empty {empty}, {time.perf_counter()-t0:.0f}s | "
          f"tokens in={tok['in']} out={tok['out']} cache={tok['cache']} "
          f"(~{(tok['in']+tok['out'])/max(1,wrote):.0f}/record)", flush=True)
    print(f"ledger run_id={run_id}:", flush=True)
    print(ledger_summary(run_id), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
