#!/usr/bin/env python3
"""Hidden HTTP smoke for cvt-l5-event-planner: replays the upstream pytest flows
(tests/test_users.py, tests/test_events.py) over `jac run --serve`. Usage: smoke.py <ws>"""
import os
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from smoke_lib import check, is_error, items, ok_resp, run  # noqa: E402


def events(srv):
    st, env = srv.call("/walker/get_all_events", {})
    check(ok_resp(st, env), f"get_all_events failed: {st} {env}")
    return [e for e in items(env) if isinstance(e, dict)]


def checks(srv):
    tag = uuid.uuid4().hex[:6]
    email = f"testuser{tag}@example.com"
    st, env, r = srv.walker("sign_new_user", email=email, password="testpassword")
    check(ok_resp(st, env) and (r or {}).get("message") == "User created successfully", f"signup: {st} {env}")
    st, env, r = srv.walker("sign_new_user", email=email, password="testpassword")
    check(is_error(st, env), f"duplicate signup should be an error: {st} {env}")

    base = len(events(srv))
    ids = []
    for n in (1, 2):
        st, env, r = srv.walker("create_event", user=email, title=f"Test event {n} {tag}",
                                image=f"https://example.com/image{n}.jpg", description=f"This is test event {n}",
                                tags=["test", "event"], location=f"Test location {n}")
        check(ok_resp(st, env) and (r or {}).get("message") == "Event created successfully" and (r or {}).get("id"),
              f"create_event: {st} {env}")
        ids.append((r or {}).get("id"))
    check(len(events(srv)) == base + 2, "event count did not grow by 2")

    st, env, r = srv.walker("get_event_by_id", event_id=ids[0])
    check(ok_resp(st, env) and (r or {}).get("creator") == email and (r or {}).get("id") == ids[0],
          f"get_event_by_id: {st} {env}")
    st, env, r = srv.walker("get_event_by_id", event_id="507f1f77bcf86cd799439011")
    check(is_error(st, env), f"unknown id should be an error: {st} {env}")

    st, env, r = srv.walker("update_event", event_id=ids[0], user=email, title="Updated test event")
    check(ok_resp(st, env) and (r or {}).get("title") == "Updated test event"
          and (r or {}).get("location") == "Test location 1", f"update_event: {st} {env}")
    st, env, r = srv.walker("update_event", event_id=ids[0], user="other@example.com", title="nope")
    check(is_error(st, env), f"update by non-creator should be an error: {st} {env}")

    st, env, r = srv.walker("delete_event", event_id=ids[0], user="other@example.com")
    check(is_error(st, env), f"delete by non-creator should be an error: {st} {env}")
    st, env, r = srv.walker("delete_event", event_id=ids[0], user=email)
    check(ok_resp(st, env) and (r or {}).get("message") == "Event deleted successfully", f"delete_event: {st} {env}")
    left = [e.get("id") for e in events(srv)]
    check(ids[0] not in left and ids[1] in left, f"wrong events after delete: {left}")

    st, env, r = srv.walker("delete_all_events", user=email)
    check(ok_resp(st, env) and (r or {}).get("message") == "All events deleted successfully",
          f"delete_all_events: {st} {env}")
    check(len(events(srv)) == 0, "events remain after delete_all_events")


if __name__ == "__main__":
    run(checks)
