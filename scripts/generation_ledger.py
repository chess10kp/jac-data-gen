#!/usr/bin/env python3
"""Durable per-call token ledger for ALL generation pipelines (SQLite WAL).

Fixes the "600M lost tokens" class of bug: usage used to live only in RAM
(_USAGE dict) and was printed once at the end — any killed run, timeout,
JSON-parse failure or is_error response silently discarded its tokens before
they were ever counted. Every driver now commits one row per model call the
moment it completes, regardless of outcome.

CLI:
  python3 generation_ledger.py summary [run_id]   totals by status
  python3 generation_ledger.py total              grand totals
"""
from __future__ import annotations
import json, sqlite3, threading, time, uuid
from pathlib import Path

DB = Path(__file__).resolve().parent.parent / "data" / "run_ledger.sqlite3"
_TLS = threading.local()
_LOCK = threading.Lock()

_SCHEMA = """
CREATE TABLE IF NOT EXISTS runs (
  run_id TEXT PRIMARY KEY, pipeline TEXT, model TEXT, note TEXT, ts REAL
);
CREATE TABLE IF NOT EXISTS calls (
  call_id TEXT PRIMARY KEY, run_id TEXT NOT NULL, pipeline TEXT NOT NULL,
  batch TEXT, record_ids TEXT, model TEXT,
  status TEXT NOT NULL,  -- ok|is_error|parse_error|timeout|spawn_error
  error TEXT,
  tok_in INTEGER DEFAULT 0, tok_out INTEGER DEFAULT 0,
  tok_cache_read INTEGER DEFAULT 0, tok_cache_write INTEGER DEFAULT 0,
  request_id TEXT, session_id TEXT,
  n_parsed INTEGER DEFAULT 0, dur_s REAL, ts REAL
);
CREATE INDEX IF NOT EXISTS idx_calls_run ON calls(run_id);
"""


def _conn() -> sqlite3.Connection:
    c = getattr(_TLS, "conn", None)
    if c is None:
        DB.parent.mkdir(parents=True, exist_ok=True)
        c = sqlite3.connect(str(DB), timeout=60)
        c.execute("PRAGMA journal_mode=WAL")
        c.execute("PRAGMA synchronous=NORMAL")
        c.executescript(_SCHEMA)
        _TLS.conn = c
    return c


def new_run(pipeline: str, model: str | None = None, note: str = "") -> str:
    run_id = f"{pipeline}-{time.strftime('%Y%m%d-%H%M%S')}-{uuid.uuid4().hex[:6]}"
    with _LOCK:
        _conn().execute("INSERT INTO runs VALUES (?,?,?,?,?)",
                        (run_id, pipeline, model, note, time.time()))
        _conn().commit()
    return run_id


def record_call(run_id: str, *, pipeline: str, status: str, batch: str | None = None,
                model: str | None = None, usage: dict | None = None,
                record_ids: list | None = None, error: str | None = None,
                n_parsed: int = 0, dur_s: float | None = None,
                request_id: str | None = None, session_id: str | None = None) -> None:
    """Commit one call row. Call for EVERY outcome — ok, is_error, parse_error,
    timeout — so no completed spend is ever lost. usage = cursor-agent `usage`
    dict (inputTokens/outputTokens/cacheReadTokens/cacheWriteTokens)."""
    u = usage or {}
    call_id = f"{run_id}-{uuid.uuid4().hex[:8]}"
    row = (call_id, run_id, pipeline, batch,
           json.dumps(record_ids) if record_ids else None, model, status,
           (error or "")[:2000],
           int(u.get("inputTokens") or 0), int(u.get("outputTokens") or 0),
           int(u.get("cacheReadTokens") or 0), int(u.get("cacheWriteTokens") or 0),
           request_id, session_id, n_parsed, dur_s, time.time())
    with _LOCK:
        _conn().execute(
            "INSERT INTO calls VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", row)
        _conn().commit()


def summary(run_id: str | None = None) -> str:
    q = ("SELECT COALESCE(status,'?'), COUNT(*), SUM(tok_in), SUM(tok_out), "
         "SUM(tok_cache_read), SUM(tok_cache_write) FROM calls "
         + ("WHERE run_id=?" if run_id else "") + " GROUP BY status ORDER BY 2 DESC")
    rows = _conn().execute(q, (run_id,) if run_id else ()).fetchall()
    out = [f"{'status':<12} {'calls':>6} {'in':>12} {'out':>11} {'cache_r':>14} {'cache_w':>12}"]
    tc = [0] * 5
    for st, n, i, o, cr, cw in rows:
        i, o, cr, cw = i or 0, o or 0, cr or 0, cw or 0
        tc = [tc[0] + i, tc[1] + o, tc[2] + cr, tc[3] + cw, tc[4] + n]
        out.append(f"{st:<12} {n:>6} {i:>12,} {o:>11,} {cr:>14,} {cw:>12,}")
    out.append(f"{'TOTAL':<12} {tc[4]:>6} {tc[0]:>12,} {tc[1]:>11,} {tc[2]:>14,} {tc[3]:>12,}")
    return "\n".join(out)


if __name__ == "__main__":
    import sys
    mode = sys.argv[1] if len(sys.argv) > 1 else "total"
    if mode == "summary":
        print(summary(sys.argv[2] if len(sys.argv) > 2 else None))
    else:
        print(summary())
