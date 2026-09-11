"""Reference harness for iss_gekichumai__dxrating__317."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_gekichumai__dxrating__317.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import pathlib

_here = pathlib.Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location(
    "iss_gekichumai__dxrating__317",
    _here / "iss_gekichumai__dxrating__317.py",
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

fresh_moderation_store = _mod.fresh_moderation_store
register_comment = _mod.register_comment
add_reply_edge = _mod.add_reply_edge
direct_replies = _mod.direct_replies
reachable_replies = _mod.reachable_replies
cascade_mark_deleted = _mod.cascade_mark_deleted
moderation_report = _mod.moderation_report

s = fresh_moderation_store()
assert isinstance(s, dict)
assert set(s.keys()) == {"comments", "replies", "rev", "nodes", "deleted", "events"}

s = fresh_moderation_store()
register_comment("root", s)
register_comment("reply_a", s)
register_comment("reply_b", s)
register_comment("shared", s)
add_reply_edge("root", "reply_a", s)
add_reply_edge("root", "reply_b", s)
add_reply_edge("reply_a", "shared", s)
add_reply_edge("reply_b", "shared", s)
got = reachable_replies("root", s)
assert got == ["reply_a", "shared", "reply_b"]
assert direct_replies("root", s) == ["reply_a", "reply_b"]
shared_count = 0
for cid in got:
    if cid == "shared":
        shared_count += 1
assert shared_count == 1

s1 = fresh_moderation_store()
register_comment("root", s1)
register_comment("reply_a", s1)
register_comment("reply_b", s1)
register_comment("shared", s1)
add_reply_edge("root", "reply_b", s1)
add_reply_edge("reply_b", "shared", s1)
add_reply_edge("root", "reply_a", s1)
add_reply_edge("reply_a", "shared", s1)

s2 = fresh_moderation_store()
register_comment("root", s2)
register_comment("reply_a", s2)
register_comment("reply_b", s2)
register_comment("shared", s2)
add_reply_edge("root", "reply_a", s2)
add_reply_edge("reply_a", "shared", s2)
add_reply_edge("root", "reply_b", s2)
add_reply_edge("reply_b", "shared", s2)
assert reachable_replies("root", s1) == reachable_replies("root", s2)

s = fresh_moderation_store()
register_comment("root", s)
caught = False
try:
    direct_replies("missing", s)
except KeyError:
    caught = True
assert caught
caught2 = False
try:
    add_reply_edge("root", "missing", s)
except KeyError:
    caught2 = True
assert caught2

s = fresh_moderation_store()
register_comment("root", s)
register_comment("reply_a", s)
add_reply_edge("root", "reply_a", s)
marked = cascade_mark_deleted("root", s)
assert marked == ["reply_a", "root"]
rep = moderation_report("root", s)
assert rep["deleted"] is True
assert rep["thread_deleted_count"] == 2

s = fresh_moderation_store()
register_comment("root", s)
register_comment("reply_a", s)
add_reply_edge("root", "reply_a", s)
rep = moderation_report("root", s)
assert rep["direct"] == ["reply_a"]
assert rep["reach"] == ["reply_a"]
assert rep["reach_count"] == 1
assert rep["deleted"] is False
assert rep["thread_deleted_count"] == 0
print("iss_gekichumai__dxrating__317 ref OK")
