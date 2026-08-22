"""Continuously drop idle jac test databases from the shared embedded PG.

Every jac test creates a new DB (jac_main_<hash>) and never drops it; the
floorfix guard leaks ~7.5MB per record. This sweeper keeps pace:
  - every 30s, list all non-template DBs and those with live connections;
  - a DB first seen >60s ago and never seen in use is dropped (WITH FORCE);
  - anything in use or younger than 60s is never touched (race-safe for the
    create->connect window of in-flight tests);
  - drops run on 8 parallel connections.
Exits when no floorfix/idiomize guard process is alive anymore.
"""
from __future__ import annotations
import subprocess, sys, threading, time
import psycopg2

import glob

def live_sockets():
    out = []
    for s in sorted(glob.glob("/tmp/jacpg-*")):
        try:
            psycopg2.connect(host=s, dbname="postgres", connect_timeout=2).close()
            out.append(s)
        except Exception:
            continue
    return out

def connect(host):
    c = psycopg2.connect(host=host, dbname="postgres", connect_timeout=5)
    c.autocommit = True
    return c

NTHREADS = 8

def guard_alive() -> bool:
    r = subprocess.run(["pgrep", "-f", "floorfix|agent_idiomize|composer_guard"],
                       capture_output=True)
    return r.returncode == 0

def sweep(mon: dict, lock: threading.Lock) -> int:
    """mon is keyed by (host, dbname). Returns total drop stats."""
    stats = []
    for host in live_sockets():
        try:
            stats.append(sweep_one(host, mon, lock))
        except Exception as e:
            print(f"[sweep {host} error] {str(e)[:80]}", flush=True)
    if not stats:
        return 0, 0, 0, 0
    return (sum(s[0] for s in stats), sum(s[1] for s in stats),
            sum(s[2] for s in stats), sum(s[3] for s in stats))

def sweep_one(host: str, mon: dict, lock: threading.Lock):
    c = connect(host); cur = c.cursor()
    cur.execute("SELECT datname FROM pg_database WHERE NOT datistemplate")
    all_db = {r[0] for r in cur.fetchall() if r[0] != "postgres"}
    cur.execute("SELECT DISTINCT datname FROM pg_stat_activity WHERE datname IS NOT NULL")
    in_use = {r[0] for r in cur.fetchall()}
    now = time.time()
    with lock:
        for d in all_db:
            mon.setdefault((host, d), time.time())
        drop = [d for d in all_db
                if d not in in_use and now - mon[(host, d)] > 60]
        for d in in_use:
            mon[(host, d)] = now  # seen in use -> reset age
    dropped: list[tuple[str, str]] = []

    def worker(queue):
        try:
            cc = connect(host)
        except Exception:
            return
        while queue:
            d = queue.pop()
            try:
                cc.cursor().execute(f'DROP DATABASE IF EXISTS "{d}" WITH (FORCE)')
                dropped.append((d, "ok"))
            except Exception as e:
                dropped.append((d, str(e)[:60]))

    queues = [sorted(drop)[i::NTHREADS] for i in range(NTHREADS)]
    ts = [threading.Thread(target=worker, args=(q,)) for q in queues if q]
    for t in ts: t.start()
    for t in ts: t.join()
    ok = sum(1 for _, s in dropped if s == "ok")
    err = len(dropped) - ok
    c.close()
    return len(all_db), len(in_use), ok, err

def main() -> int:
    mon: dict[str, float] = {}
    lock = threading.Lock()
    idle_rounds = 0
    while True:
        try:
            n, inu, ok, err = sweep(mon, lock)
            ts = time.strftime("%T")
            print(f"[{ts}] dbs={n} in_use={inu} dropped={ok} err={err}", flush=True)
        except Exception as e:
            print(f"[sweep error] {e}", flush=True)
            idle_rounds += 1
        if not guard_alive():
            idle_rounds += 1
            if idle_rounds >= 2:
                print("[sweeper] guard gone — final sweep and exit", flush=True)
                try:
                    mon = {d: 0 for d in mon}  # force-drop everything left
                    sweep(mon, lock)
                except Exception as e:
                    print(f"[final sweep error] {e}", flush=True)
                return 0
        else:
            idle_rounds = 0
        time.sleep(30)

if __name__ == "__main__":
    sys.exit(main())
