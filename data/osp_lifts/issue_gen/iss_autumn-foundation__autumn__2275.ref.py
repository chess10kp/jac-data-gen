"""Reference harness: exercises every public function of iss_autumn-foundation__autumn__2275."""
import importlib

mod = importlib.import_module("iss_autumn-foundation__autumn__2275")
CommentStore = mod.CommentStore
CrossRecordError = mod.CrossRecordError

s = CommentStore()
REC_A = ("ticket", "A")
REC_B = ("post", "B")
s.add_comment("a1", REC_A)
s.add_comment("a2", REC_A, parent_id="a1")     # reply depth 1
s.add_comment("a3", REC_A, parent_id="a2")     # reply depth 2
s.add_comment("b1", REC_B)

# Write path rejects cross-record replies.
try:
    s.add_comment("bad", REC_B, parent_id="a1")
    raise SystemExit("expected CrossRecordError")
except CrossRecordError:
    pass

# Imported row: legal at storage level, crosses into record A's subtree.
s.import_comment("x1", REC_B, parent_id="a2")

assert s.scoped_subtree("a1") == ["a1", "a2", "a3"]          # scoped query
assert s.unscoped_cascade_reach("a1") == ["a1", "a2", "a3", "x1"]
assert s.spill_set("a1") == ["x1"]

# The honest delete repairs BOTH counters and reports the spill.
before_a = s.counts[REC_A]
before_b = s.counts[REC_B]
report = s.hard_delete_subtree("a1")
assert report["scoped"] == 3
assert report["total"] == 4
assert report["spill"] == 1
assert report["levels"] == [1, 1]        # a1 root; a2 at depth1; a3 depth2
assert s.counts[REC_A] == before_a - 3
assert s.counts[REC_B] == before_b - 1   # the corruption is now repaired
assert "x1" not in s.parent_of and "a3" not in s.parent_of

# Clean subtree with no cross-record spill: totals agree.
t = CommentStore()
t.add_comment("r1", REC_A)
t.add_comment("r2", REC_A, parent_id="r1")
rep = t.hard_delete_subtree("r1")
assert rep == {"scoped": 2, "total": 2, "spill": 0, "levels": [1]}
assert t.counts[REC_A] == 0

# Deep chain reaches beyond depth 2.
d = CommentStore()
d.add_comment("c0", REC_A)
for i in range(1, 6):
    d.add_comment("c%d" % i, REC_A, parent_id="c%d" % (i - 1))
rep = d.hard_delete_subtree("c0")
assert rep["levels"] == [1, 1, 1, 1, 1]
assert rep["total"] == 6
assert d.counts[REC_A] == 0

# Directed errors on unknown parents.
u = CommentStore()
try:
    u.add_comment("z", REC_A, parent_id="ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
try:
    u.import_comment("z", REC_A, parent_id="ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
