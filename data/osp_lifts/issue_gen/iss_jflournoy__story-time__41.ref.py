"""Reference harness for iss_jflournoy__story-time__41."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_jflournoy__story-time__41.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import pathlib

_mod_path = pathlib.Path(__file__).with_name("iss_jflournoy__story-time__41.py")
_spec = importlib.util.spec_from_file_location("_mod", _mod_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

STATUS_OUTLINE = _mod.STATUS_OUTLINE
REL_REQUIRES = _mod.REL_REQUIRES
fresh_outline_store = _mod.fresh_outline_store
register_beat = _mod.register_beat
link_child = _mod.link_child
get_descendant_ids = _mod.get_descendant_ids
list_session_beats = _mod.list_session_beats
delete_beat_cascade = _mod.delete_beat_cascade
add_world_ref = _mod.add_world_ref
world_refs_for_beat = _mod.world_refs_for_beat

assert STATUS_OUTLINE == "outline"
assert REL_REQUIRES == "requires"

s0 = fresh_outline_store()
assert isinstance(s0, _mod.OutlineStore)
assert list_session_beats("sess", s0) == []

s = fresh_outline_store()
register_beat("root", "sess", 0, 0, "root", STATUS_OUTLINE, s)
register_beat("child", "sess", 0, 1, "child", STATUS_OUTLINE, s, "root")
register_beat("grand", "sess", 0, 2, "grand", STATUS_OUTLINE, s, "child")
assert get_descendant_ids("root", s) == ["child", "grand"]
assert delete_beat_cascade("root", s) == ["child", "grand", "root"]
assert list_session_beats("sess", s) == []

s2 = fresh_outline_store()
register_beat("hub", "sess", 0, 0, "hub", STATUS_OUTLINE, s2)
register_beat("left", "sess", 0, 1, "left", STATUS_OUTLINE, s2)
register_beat("right", "sess", 1, 1, "right", STATUS_OUTLINE, s2)
register_beat("leaf_l", "sess", 0, 2, "leaf_l", STATUS_OUTLINE, s2)
register_beat("leaf_r", "sess", 1, 2, "leaf_r", STATUS_OUTLINE, s2)
link_child("hub", "left", s2)
link_child("hub", "right", s2)
link_child("right", "leaf_r", s2)
link_child("left", "leaf_l", s2)
assert sorted(get_descendant_ids("hub", s2)) == ["leaf_l", "leaf_r", "left", "right"]

s3 = fresh_outline_store()
register_beat("a", "sess", 0, 0, "a", STATUS_OUTLINE, s3)
try:
    get_descendant_ids("ghost", s3)
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    delete_beat_cascade("ghost", s3)
    raise AssertionError("expected KeyError")
except KeyError:
    pass

s4 = fresh_outline_store()
register_beat("b2", "sess", 1, 0, "b2", STATUS_OUTLINE, s4)
register_beat("a1", "sess", 0, 0, "a1", STATUS_OUTLINE, s4)
register_beat("c3", "sess", 0, 1, "c3", STATUS_OUTLINE, s4, "a1")
assert list_session_beats("sess", s4) == ["a1", "b2", "c3"]

s5 = fresh_outline_store()
register_beat("beat", "sess", 0, 0, "beat", STATUS_OUTLINE, s5)
add_world_ref("beat", "fact_a", REL_REQUIRES, s5)
add_world_ref("beat", "fact_b", "references", s5)
assert world_refs_for_beat("beat", s5) == [("fact_a", "requires"), ("fact_b", "references")]
try:
    add_world_ref("ghost", "fact", REL_REQUIRES, s5)
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    world_refs_for_beat("ghost", s5)
    raise AssertionError("expected KeyError")
except KeyError:
    pass
print("iss_jflournoy__story-time__41 ref OK")
