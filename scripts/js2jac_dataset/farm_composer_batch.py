#!/usr/bin/env python3
"""Batched composer walker-gen via cursor-agent -- FARM burndown driver.

Mirror of cursor_composer_batch.py (same MCP-strip, ask-mode, process-group
teardown, token accounting, resumable-by-id output) but the task is: given a
Mongo-derived Jac node archetype, AUTHOR the idiomatic CRUD walker-set for it.

Walker NAMES + entry contract are prescribed so the behavioral gate's manifest
(farm_prep.derive_manifest) matches deterministically; composer writes the actual
Jac bodies (real generation, gated by execution -- not templating).

Output contract: {"id","candidate"} JSONL -> farm_guard.py.
"""
from __future__ import annotations
import argparse, atexit, json, os, re, signal, subprocess, sys, threading, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from generation_ledger import new_run, record_call
from generation_ledger import summary as ledger_summary

WS = "/tmp/cursor_ws"
_BLOCK = re.compile(r"===ID\s+(\S+?)===\s*(.*?)(?=(?:===ID\s+\S+?===)|\Z)", re.S)
_FENCE = re.compile(r"```(?:jac)?\s*\n(.*?)```", re.S)

_LIVE_PGIDS: set[int] = set()
_LOCK = threading.Lock()
_USAGE = {"in": 0, "out": 0, "cache": 0}

SYS = (
    "You translate Mongo/Beanie data models into idiomatic Jac graph walkers. "
    "Jac uses braces and semicolons (never Python colons); nodes/edges persist on "
    "`root`; walkers carry request logic. Output valid Jac only, no prose."
)

IDIOM = """Idiom (from the shipped todo_app):
  walker:pub create_Todo {
      has title: str; has done: bool = False;
      can go with Root entry { new = here ++> Todo(title=self.title, done=self.done); report new; }
  }
  walker:pub list_Todo   { can go with Root entry { report [-->[?:Todo]]; } }
  walker:pub update_Todo { has val: bool; can go with Todo entry { here.done = self.val; report here; } }
  walker:pub delete_Todo { can go with Todo entry { del here; report "deleted"; } }
Rules: `here ++> Node(..)` creates+links to root; `[-->[?:Node]]` reads; mutate
fields in place (auto-persists, no .save()); `del here` deletes. Concrete types
only, never `any`. Do NOT redefine the given node/edge archetypes."""


def _fields_decl(scalars):
    return "; ".join(f"has {n}: {t}" for n, t, _hd in scalars)


def build_prompt(recs: list[dict]) -> str:
    parts = [SYS, "\n\n", IDIOM,
             "\n\nWrite the CRUD walker-set for EACH node below. Output EXACTLY, in order:\n"
             "===ID <id>===\n```jac\n<walkers only>\n```\n"
             "Required walkers per node X (these exact names):\n"
             "  create_X (has-params for every scalar field; `with Root entry`),\n"
             "  list_X (`with Root entry`, reports all X),\n"
             "  update_X (`has val: <type>`; `with X entry`; sets the named update field to self.val) -- only if an update field is given,\n"
             "  delete_X (`with X entry`, `del here`).\n"]
    for r in recs:
        uf = r.get("update_field")
        parts.append(
            f"\n===ID {r['id']}===  node {r['node']}"
            f"  (scalar fields: {_fields_decl(r['scalar_fields'])};"
            f" update field: {uf or 'none — omit update_' + r['node']})\n"
            f"ARCHETYPE (given, do not redefine):\n{r['archetype']}\n")
        ctx = r.get("handler_context")
        if ctx:
            parts.append(
                "REAL FastAPI+Beanie handler code for this node — translate its behavior "
                "faithfully into the walkers above (keep field-level updates, ownership, and "
                "response intent; the walkers must still satisfy the CRUD contract):\n"
                f"{ctx}\n")
    return "".join(parts)


def parse_result(text: str) -> dict[str, str]:
    out = {}
    for m in _BLOCK.finditer(text or ""):
        fm = _FENCE.search(m.group(2))
        if fm:
            out[m.group(1)] = fm.group(1).strip()
    return out


def call_agent(batch_file: str, model: str, timeout: int,
               run_id: str = "-") -> dict[str, str]:
    recs = json.loads(Path(batch_file).read_text())
    t0 = time.perf_counter()
    rids, batch_name = [r["id"] for r in recs], Path(batch_file).name
    prompt = build_prompt(recs)
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
        record_call(run_id, pipeline="farm-composer", batch=batch_name, model=model,
                    status="timeout", record_ids=rids, error=f"timeout after {timeout}s",
                    dur_s=time.perf_counter() - t0)
        return {}
    finally:
        with _LOCK:
            _LIVE_PGIDS.discard(pgid)
    try:
        d = json.loads(out)
    except Exception as e:  # noqa: BLE001
        record_call(run_id, pipeline="farm-composer", batch=batch_name, model=model,
                    status="parse_error", record_ids=rids,
                    error=f"{e}: {(out or '')[:300]}", dur_s=time.perf_counter() - t0)
        return {}
    u = d.get("usage") or {}
    with _LOCK:
        _USAGE["in"] += u.get("inputTokens", 0); _USAGE["out"] += u.get("outputTokens", 0)
        _USAGE["cache"] += u.get("cacheReadTokens", 0)
    res = parse_result(d.get("result", ""))
    record_call(run_id, pipeline="farm-composer", batch=batch_name, model=model,
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
    atexit.register(_mcp_reenable); atexit.register(_sweep)
    for s in (signal.SIGINT, signal.SIGTERM):
        signal.signal(s, lambda *_: (_sweep(), _mcp_reenable(), sys.exit(1)))
    run_id = new_run("farm-composer", model=args.model)
    _mcp_disable_all()

    out_path = Path(args.out)
    done = set()
    if out_path.exists():
        for line in out_path.read_text().splitlines():
            if line.strip(): done.add(json.loads(line)["id"])
    batches = sorted(Path(args.batch_dir).glob("*.json"))
    todo = [bf for bf in batches
            if {r["id"] for r in json.loads(bf.read_text())} - done]
    print(f"FARM cursor-agent: {len(todo)} batches (of {len(batches)}), "
          f"model={args.model}, {args.workers} workers, MCP off, ask-mode", flush=True)

    fh = open(out_path, "a")
    t0, wrote, empty = time.perf_counter(), 0, 0
    try:
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            futs = [ex.submit(call_agent, str(bf), args.model, args.timeout, run_id)
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
                          f"empty {empty}  ~{per:.0f} tok/record", flush=True)
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
