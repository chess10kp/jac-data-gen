#!/usr/bin/env python3
"""Stage 3 (LLM cleanup pass) for js2jac — fork of scripts/cursor_composer_batch.py.

Same batched cursor-agent driver (MCP stripped, ask-mode, process-group
teardown), but the prompt is the js2jac cleanup contract driven by
strip_policy.json instead of the py2jac idiomize seam.

Per record the model gets the React/TS SOURCE and (when the converter already
produced one) the FLOOR Jac, and must return ONE of:
  - a cleaned/idiomatic ```jac block  (strip + rewrite per policy), or
  - the literal token  REJECT  (lossy construct the policy says to drop)

Output contract for the guard: {id, candidate} JSONL, candidate omitted/"REJECT"
means dropped. ids are strings (repo__path), not ints.

faithful_mode (--faithful) promotes every fidelity:"lossy" policy entry to
reject — the single knob that switches the surface-syntax dataset (strip hard)
to the round-trip-faithful dataset (reject anything lossy).
"""
from __future__ import annotations
import argparse, atexit, json, os, re, signal, subprocess, sys, threading, time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

WS = "/tmp/cursor_ws"
POLICY_PATH = Path(__file__).resolve().parent / "strip_policy.json"

# string ids: everything up to the next ===ID or EOF
_BLOCK = re.compile(r"===ID\s+(.+?)===\s*(.*?)(?=(?:===ID\s+)|\Z)", re.S)
_FENCE = re.compile(r"```(?:jac)?\s*\n(.*?)```", re.S)
_REJECT = re.compile(r"^\s*REJECT\b", re.I)

_LIVE_PGIDS: set[int] = set()
_LOCK = threading.Lock()
_USAGE = {"in": 0, "out": 0, "cache": 0}


def build_system_prompt(faithful: bool) -> str:
    """Compact hard rules + the strip policy rendered as an action table."""
    pol = json.loads(POLICY_PATH.read_text())
    lines: list[str] = []
    for code, e in pol.items():
        if code.startswith("_"):
            continue
        if code == "E7205":
            lines.append(f"{code} (const-init wall) — dispatch on what the export initializes to:")
            for shape, d in e["dispatch"].items():
                act = "reject" if (faithful and d["fidelity"] == "lossy") else d["action"]
                lines.append(f"    - {shape}: {act.upper()} — {d['rule']}")
            continue
        act = "reject" if (faithful and e.get("fidelity") == "lossy") else e["action"]
        lines.append(f"{code} {e.get('msg','')} — {act.upper()}: {e['rule']}")
    policy_txt = "\n".join(lines)
    mode = ("FAITHFUL mode: anything that would drop real behavior => REJECT."
            if faithful else
            "SYNTAX mode: strip lossy constructs and keep the file convertible.")
    return f"""You are an expert Jac (Jaseci Labs) engineer cleaning up machine-converted
React/TypeScript so it becomes valid, idiomatic Jac for a translation dataset.

You get, per record: the original TS/React SOURCE and, when the converter
already produced one, the FLOOR Jac (already valid Jac — idiomize it, keep the
component's exported names EXACTLY). When there is no FLOOR, the file failed to
convert: apply the policy below to strip/rewrite it into convertible Jac.

{mode}

For EACH record output EXACTLY, in order:
===ID <id>===
```jac
<cleaned jac>
```
or, if the policy says this file/construct must be dropped:
===ID <id>===
REJECT

HARD RULES (any violation discards that record):
1. VALID JAC ONLY — braces {{ }} and semicolons ;, never Python colon-indent.
2. Keep exported component/function names EXACTLY.
3. NEVER emit `any`; infer concrete types.
4. Output nothing but the ===ID blocks (fenced jac or REJECT). No prose.

CLEANUP POLICY (by converter error / construct):
{policy_txt}
"""


def _extract(seg: str) -> str | None:
    if _REJECT.match(seg):
        return "REJECT"
    m = _FENCE.search(seg)
    return m.group(1).strip() if m else None


def parse_result(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    for m in _BLOCK.finditer(text or ""):
        code = _extract(m.group(2))
        if code:
            out[m.group(1).strip()] = code
    return out


def build_prompt(recs: list[dict]) -> str:
    parts = ["Clean up EACH record below per the policy.\n"]
    for r in recs:
        floor = r.get("floor_jac")
        parts.append(f"\n===ID {r['id']}===  (status: {r['status']})\n"
                     f"SOURCE:\n{r['source_js'][:3500]}\n")
        if floor:
            parts.append(f"\nFLOOR (valid Jac — idiomize, do not reject):\n{floor[:2500]}\n")
        else:
            parts.append("\nFLOOR: (none — converter rejected this file; strip/rewrite or REJECT)\n")
    return "".join(parts)


def call_agent(batch_file: str, model: str, sysprompt: str, timeout: int) -> dict[str, str]:
    recs = json.loads(Path(batch_file).read_text())
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
        return {}
    finally:
        with _LOCK:
            _LIVE_PGIDS.discard(pgid)
    try:
        d = json.loads(out)
    except Exception:  # noqa: BLE001
        return {}
    u = d.get("usage") or {}
    with _LOCK:
        _USAGE["in"] += u.get("inputTokens", 0); _USAGE["out"] += u.get("outputTokens", 0)
        _USAGE["cache"] += u.get("cacheReadTokens", 0)
    if d.get("is_error"):
        return {}
    return parse_result(d.get("result", ""))


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
    with _LOCK:
        pgids = list(_LIVE_PGIDS)
    for g in pgids:
        _kill_pg(g)
    for pat in ("cursor-agent", "cursor.*composer", "browsermcp", "mcp-server"):
        subprocess.run(["pkill", "-9", "-f", pat],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--batch-dir", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--model", default="composer-2.5")
    ap.add_argument("--workers", type=int, default=6)
    ap.add_argument("--timeout", type=int, default=360)
    ap.add_argument("--faithful", action="store_true",
                    help="promote every lossy strip to reject (round-trip dataset)")
    args = ap.parse_args()

    os.makedirs(WS, exist_ok=True); os.makedirs("/tmp/cursor_tmp", exist_ok=True)
    atexit.register(_mcp_reenable); atexit.register(_sweep)
    for s in (signal.SIGINT, signal.SIGTERM):
        signal.signal(s, lambda *_: (_sweep(), _mcp_reenable(), sys.exit(1)))
    _mcp_disable_all()

    sysprompt = build_system_prompt(args.faithful)
    out_path = Path(args.out)
    done: set[str] = set()
    if out_path.exists():
        for line in out_path.read_text().splitlines():
            if line.strip(): done.add(json.loads(line)["id"])
    batches = sorted(Path(args.batch_dir).glob("*.json"))
    todo = [bf for bf in batches
            if {r["id"] for r in json.loads(bf.read_text())} - done]
    print(f"js2jac cleanup: {len(todo)} batches (of {len(batches)}), model={args.model}, "
          f"{args.workers} workers, faithful={args.faithful}, MCP off, ask-mode", flush=True)

    fh = open(out_path, "a")
    t0, wrote, empty = time.perf_counter(), 0, 0
    try:
        with ThreadPoolExecutor(max_workers=args.workers) as ex:
            futs = [ex.submit(call_agent, str(bf), args.model, sysprompt, args.timeout)
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
          f"tokens in={tok['in']} out={tok['out']} cache={tok['cache']}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
