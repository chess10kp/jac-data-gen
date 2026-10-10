#!/usr/bin/env python3
"""Hidden HTTP smoke for cvt-l5-book-catalog: exercises every endpoint of the Beanie demo
API (health, create/list/get/update/delete, genre stats) over `jac run --serve`."""
import os
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from smoke_lib import check, is_error, items, ok_resp, run  # noqa: E402


def checks(srv):
    st, env, r = srv.walker("health")
    check(ok_resp(st, env) and (r or {}).get("status") == "healthy", f"health: {st} {env}")
    tag = uuid.uuid4().hex[:6]
    author = "Tolkien " + tag
    made = []
    for t, g in (("Hobbit", ["fantasy", "kids-" + tag]), ("Silmarillion", ["fantasy"])):
        st, env, r = srv.walker("create_book", title=f"{t} {tag}", author=author, genres=g, pages=300)
        check(ok_resp(st, env) and (r or {}).get("id") and (r or {}).get("in_stock") is True, f"create_book: {st} {env}")
        made.append(r or {})
    st, env, r = srv.walker("list_books", author=author)
    titles = [b.get("title") for b in (r or {}).get("books", [])]
    check(ok_resp(st, env) and (r or {}).get("count") == 2 and titles == [f"Silmarillion {tag}", f"Hobbit {tag}"],
          f"list_books(author): {st} {env}")
    st, env, r = srv.walker("get_book", book_id=made[0].get("id"))
    check(ok_resp(st, env) and (r or {}).get("title") == f"Hobbit {tag}", f"get_book: {st} {env}")
    st, env, r = srv.walker("get_book", book_id="000000000000000000000000")
    check(is_error(st, env), f"missing book should be an error: {st} {env}")
    st, env, r = srv.walker("update_book", book_id=made[0].get("id"), rating=4.8)
    check(ok_resp(st, env) and (r or {}).get("rating") == 4.8 and (r or {}).get("pages") == 300,
          f"update_book: {st} {env}")
    st, env = srv.call("/walker/genre_stats", {})
    rows = items(env)
    kid = [x for x in rows if isinstance(x, dict) and x.get("_id") == "kids-" + tag]
    check(ok_resp(st, env) and len(kid) == 1 and kid[0].get("count") == 1, f"genre_stats: {st} {env}")
    st, env, r = srv.walker("delete_book", book_id=made[1].get("id"))
    check(ok_resp(st, env), f"delete_book: {st} {env}")
    st, env, r = srv.walker("list_books", author=author)
    check((r or {}).get("count") == 1, f"after delete: {env}")
    st, env, r = srv.walker("delete_book", book_id=made[1].get("id"))
    check(is_error(st, env), f"second delete should be an error: {st} {env}")


if __name__ == "__main__":
    run(checks)
