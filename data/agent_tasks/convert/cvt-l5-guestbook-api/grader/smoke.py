#!/usr/bin/env python3
"""Hidden HTTP smoke for cvt-l5-guestbook-api: mirrors upstream test_e2e.py over
`jac run --serve` (POST /walker/<name>). Usage: smoke.py <workspace>"""
import os
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from smoke_lib import check, items, ok_resp, one, run  # noqa: E402


def entries(srv):
    st, env, r = srv.walker("retrieve_entries")
    check(ok_resp(st, env) and isinstance(r, dict) and isinstance(r.get("entries"), list),
          f"retrieve_entries shape wrong: {st} {env}")
    return (r or {}).get("entries", []) if isinstance(r, dict) else []


def add(srv, name, text):
    st, env, r = srv.walker("add_entry", name=name, entry=text)
    msg = (r or {}).get("message", "") if isinstance(r, dict) else ""
    check(ok_resp(st, env) and msg.startswith("New entry added with ID: "), f"add_entry wrong: {st} {env}")
    return msg.split("ID: ")[-1]


def checks(srv):
    st, env, r = srv.walker("welcome")
    check(ok_resp(st, env) and "Welcome to the FastAPI + Okteto" in (r or {}).get("message", ""),
          f"welcome wrong: {st} {env}")
    tag = uuid.uuid4().hex[:6]
    base = len(entries(srv))
    ids = [add(srv, n + tag, f"{n} was here") for n in ("Alice", "Bob", "Charlie")]
    cur = entries(srv)
    check(len(cur) == base + 3, f"expected {base + 3} entries, got {len(cur)}")
    mine = [e for e in cur if e.get("id") in ids]
    check(len(mine) == 3 and all({"id", "name", "entry"} <= set(e) for e in mine), f"entries missing fields: {cur}")
    check(sorted(e.get("name") for e in mine) == sorted(n + tag for n in ("Alice", "Bob", "Charlie")),
          f"names wrong: {mine}")
    st, env, r = srv.walker("delete_entry", id=ids[1])
    check(ok_resp(st, env) and "deleted successfully" in (r or {}).get("message", ""), f"delete wrong: {st} {env}")
    left = [e.get("id") for e in entries(srv)]
    check(ids[1] not in left and ids[0] in left and ids[2] in left, f"delete removed wrong entries: {left}")
    st, env, r = srv.walker("delete_entry", id="507f1f77bcf86cd799439011")
    check(ok_resp(st, env) and "deleted successfully" in (r or {}).get("message", ""),
          f"delete of unknown id should still succeed: {st} {env}")
    check(len(entries(srv)) == base + 2, "unknown-id delete changed the entry count")


if __name__ == "__main__":
    run(checks)
