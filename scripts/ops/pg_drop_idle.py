#!/usr/bin/env python
"""Drop idle jac_main_* scratch DBs from the live embedded Postgres.

jac leaks one ~9MB database per `jac test` invocation; this reclaims them
online (no idle requirement). Safety:
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

conn = None
for sock in glob.glob("/tmp/jacpg-*"):
    try:
        conn = psycopg2.connect(host=sock, user=os.environ.get("USER", "jac"),
                                dbname="postgres", connect_timeout=5)
        break
    except Exception:
        conn = None
if conn is None:
    print("ERR no-connection")
    sys.exit(0)

conn.autocommit = True  # DROP DATABASE cannot run in a transaction block
cur = conn.cursor()
cur.execute("SET lock_timeout = '5s'")

cur.execute("SELECT datname, oid, pg_database_size(oid) FROM pg_database "
            "WHERE datname LIKE 'jac\\_main\\_%'")
dbs = cur.fetchall()
cur.execute("SELECT datname FROM pg_stat_activity WHERE datname IS NOT NULL")
busy = {r[0] for r in cur.fetchall()}

now = time.time()
dropped = busy_skip = age_skip = errors = 0
freed = 0
for name, oid, size in dbs:
    if name in busy:
        busy_skip += 1
        continue
    try:
        if now - os.path.getmtime(os.path.join(CACHE, str(oid))) < AGE_MIN * 60:
            age_skip += 1
            continue
    except OSError:
        pass
    try:
        cur.execute(f'DROP DATABASE "{name}"')
        dropped += 1
        freed += size
    except Exception:
        errors += 1  # raced with a connection — next round gets it

cur.execute("SELECT count(*), coalesce(sum(pg_database_size(datname)), 0) "
            "FROM pg_database WHERE datname LIKE 'jac\\_main\\_%'")
left, left_sz = cur.fetchone()
conn.close()
print(f"OK dropped={dropped} freed_mb={freed // 1048576} "
      f"busy_skip={busy_skip} age_skip={age_skip} errors={errors} "
      f"left={left} left_mb={left_sz // 1048576}")
