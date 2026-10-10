#!/usr/bin/env python3
"""Hidden HTTP smoke for cvt-l5-networking-bingo: register two members, give one traits,
create the other's board, play a bingo round, all over `jac run --serve`."""
import os
import random
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from smoke_lib import check, ok_resp, one, run  # noqa: E402


def grid():
    return [[r * 5 + c + 1 for c in range(5)] for r in range(5)]


def checks(srv):
    st, env = srv.call("/walker/hc", {})
    check(ok_resp(st, env) and one(env) == "server is running", f"hc: {st} {env}")
    tag = uuid.uuid4().hex[:6]
    st, env, a = srv.walker("add_or_get_user", name="park", discord="park#" + tag)
    st2, env2, b = srv.walker("add_or_get_user", name="choi", discord="choi#" + tag)
    check(ok_resp(st, env) and ok_resp(st2, env2) and (b or {}).get("user_id") == (a or {}).get("user_id", -9) + 1,
          f"add_or_get_user ids: {env} {env2}")
    st, env, again = srv.walker("add_or_get_user", name="park", discord="park#" + tag)
    check((again or {}).get("user_id") == (a or {}).get("user_id"), f"known user should keep id: {env}")
    uid = random.randint(10**6, 10**9)
    gid = uid + 1
    st, env, r = srv.walker("get_bingo_board", user_id=uid)
    check(ok_resp(st, env) and (r or {}).get("ok") is False, f"missing board: {env}")
    st, env, r = srv.walker("new_bingo_board", user_id=uid, board=grid())
    check((r or {}).get("ok") is True, f"new_bingo_board: {env}")
    st, env, r = srv.walker("new_bingo_board", user_id=uid, board=grid())
    check((r or {}).get("ok") is False, f"duplicate board should give ok=False: {env}")
    st, env, r = srv.walker("set_attr", user_id=gid, attribute=[0, 12, 24])
    check((r or {}).get("ok") is True, f"set_attr: {env}")
    st, env, r = srv.walker("get_attr", user_id=gid)
    check((r or {}).get("attribute") == [0, 12, 24], f"get_attr: {env}")
    st, env, r = srv.walker("add_bingo", user_id=uid, gave_id=gid)
    check((r or {}).get("ok") is True, f"add_bingo: {env}")
    st, env, r = srv.walker("get_bingo_board", user_id=uid)
    board = (r or {}).get("board") or [[0] * 5] * 5
    check(board[0][0] == -999 and board[2][2] == -987 and board[4][4] == -975 and board[0][1] == 2,
          f"marked board wrong: {env}")
    check((r or {}).get("gave_ids") == [gid], f"gave_ids wrong: {env}")
    st, env, r = srv.walker("add_bingo", user_id=uid + 7, gave_id=gid)
    check((r or {}).get("ok") is False, f"unknown board should give ok=False: {env}")


if __name__ == "__main__":
    run(checks)
