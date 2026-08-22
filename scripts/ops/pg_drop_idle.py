#!/usr/bin/env python
"""Drop idle jac_main_* scratch DBs from EVERY live embedded Postgres.

jac leaks one ~9MB database per `jac test` invocation; this reclaims them
online (no idle requirement). Each pipeline worker boots its OWN cluster
(separate /tmp/jacpg-* socket), so we sweep all of them, not just the first.

Safety:
  - DBs with any active connection (pg_stat_activity) are skipped
  - plain DROP DATABASE (no FORCE): races with a new connection fail
    safely and are retried next round
  - DBs younger than AGE_MIN minutes (base/<oid> dir mtime) are skipped
    so an in-flight test that hasn't connected yet can't lose its DB
jac_shell_* (interactive shell sessions) are never touched.
"""
import glob
import os
import sys
import time

AGE_MIN = int(sys.argv[1]) if len(sys.argv) > 1 else 2
CACHE = os.path.expanduser("~/.cache/jac/pg/main/base")

try:
    import psycopg2
except ImportError:
    print("ERR no-psycopg2")
    sys.exit(0)

tot_dropped = tot_busy = tot_age = tot_err = 0
tot_freed = tot_left = tot_left_sz = 0
clusters = 0

for sock in sorted(set(glob.glob("/tmp/jacpg-*"))):
    try:
        conn = psycopg2.connect(host=sock, user=os.environ.get("USER", "jac"),
                                dbname="postgres", connect_timeout=3)
    except Exception:
        continue          # dead/stale socket — skip
    clusters += 1
    conn.autocommit = True  # DROP DATABASE cannot run in a transaction block
    cur = conn.cursor()
    cur.execute("SET lock_timeout = '5s'")

    cur.execute("SELECT datname, oid, pg_database_size(oid) FROM pg_database "
                "WHERE datname LIKE 'jac\\_main\\_%'")
    dbs = cur.fetchall()
    if not dbs:
        conn.close()
        continue
    cur.execute("SELECT datname FROM pg_stat_activity WHERE datname IS NOT NULL")
    busy = {r[0] for r in cur.fetchall()}

    now = time.time()
    for name, oid, size in dbs:
        if name in busy:
            tot_busy += 1
            continue
        try:
            if now - os.path.getmtime(os.path.join(CACHE, str(oid))) < AGE_MIN * 60:
                tot_age += 1
                continue
        except OSError:
            pass
        try:
            cur.execute(f'DROP DATABASE "{name}"')
            tot_dropped += 1
            tot_freed += size
        except Exception:
            tot_err += 1  # raced with a connection — next round gets it

    cur.execute("SELECT count(*), coalesce(sum(pg_database_size(datname)), 0) "
                "FROM pg_database WHERE datname LIKE 'jac\\_main\\_%'")
    left, left_sz = cur.fetchone()
    tot_left += left
    tot_left_sz += left_sz
    conn.close()

if clusters == 0:
    print("ERR no-connection")
else:
    print(f"OK dropped={tot_dropped} freed_mb={tot_freed // 1048576} "
          f"busy_skip={tot_busy} age_skip={tot_age} errors={tot_err} "
          f"left={tot_left} left_mb={tot_left_sz // 1048576} "
          f"clusters={clusters}")
