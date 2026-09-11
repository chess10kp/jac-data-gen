"""Reference harness: exercises every public function of iss_PersonalClaw__PersonalClaw__761."""
from iss_PersonalClaw__PersonalClaw__761 import (
    TagStore,
    ancestors,
    descendants,
    merge_tags,
    set_parent,
)

store = TagStore()
store.add_tag(2, "zfs")
store.add_tag(1, "homelab", parent_id=2)
store.add_tag(3, "pools", parent_id=1)
store.add_tag(4, "hardware", parent_id=None)

assert ancestors(store, 3) == [1, 2]
assert ancestors(store, 2) == []
assert descendants(store, 2) == [1, 3]
assert not descendants(store, 3)

# set_tag_parent rejects self- and multi-hop cycles.
try:
    set_parent(store, 2, 2)
    raise AssertionError("expected tag_cycle")
except ValueError as e:
    assert str(e) == "tag_cycle"
try:
    set_parent(store, 2, 3)  # 3 descends from 2
    raise AssertionError("expected tag_cycle")
except ValueError as e:
    assert str(e) == "tag_cycle"

# The issue's exact repro: merge a tag INTO its own child.
result = merge_tags(store, 2, 1)
assert result == {"moved": 1}
assert store.parent[1] is None, "survivor must not point at itself"
assert store.parent[3] == 1
assert 1 in ancestors(store, 3) and 2 not in ancestors(store, 3)

# Normal merge re-parents children onto the survivor.
other = TagStore()
for tid, name in [(10, "root"), (11, "left"), (12, "right"), (13, "leaf")]:
    other.add_tag(tid, name)
set_parent(other, 11, 10)
set_parent(other, 12, 10)
set_parent(other, 13, 11)
assert merge_tags(other, 11, 12) == {"moved": 1}
assert other.parent[13] == 12
assert descendants(other, 10) == [12, 13]

print("iss_PersonalClaw__PersonalClaw__761 ref OK")
