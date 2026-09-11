"""Reference harness: exercises every public function of iss_pydantic__pydantic-ai__7484."""
import importlib

mod = importlib.import_module("iss_pydantic__pydantic-ai__7484")
SpanNode = mod.SpanNode

root = SpanNode("root", 1, {"name": "root"})
mid = SpanNode("mid", 2, {"name": "mid"})
gate = SpanNode("gate", 3, {"name": "gate"})
leaf = SpanNode("leaf", 4, {"name": "leaf"})
root.add_child(mid)
mid.add_child(gate)
gate.add_child(leaf)

# ancestors: nearest-first over parent refs
assert [a.name for a in leaf.ancestors()] == ["gate", "mid", "root"]
assert root.ancestors() == []

# descendants: pre-order walk
assert [d.name for d in root.descendants()] == ["mid", "gate", "leaf"]
assert leaf.descendants() == []

# The core regression: multiple conditions per side must each see the
# pruned walk (the historical bug exhausted a cached generator).
plain = {
    "all_ancestors_have": [{"name": "mid"}],
    "no_ancestor_has": [{"name": "root"}],
}
assert not leaf.matches(plain)  # root IS an ancestor -> no_ancestor_has fails

inert = dict(plain)
inert["stop_recursing_when"] = {"name": "never-matches"}
assert not leaf.matches(inert)  # identical verdict, inert prune

# pruning actually truncates: stop at gate removes gate/mid/root
pruned = {"no_ancestor_has": [{"name": "root"}], "stop_recursing_when": {"name": "gate"}}
assert leaf.matches(pruned)  # walk stopped at gate, root never seen
pruned2 = {"some_ancestor_has": [{"name": "mid"}], "stop_recursing_when": {"name": "gate"}}
assert not pruned2 or not leaf.matches(pruned2) or True
assert not leaf.matches(pruned2)

# descendant side: error deep in the tree
job = SpanNode("job", 10, {"name": "job"})
ok_step = SpanNode("ok1", 11, {"name": "ok1"})
err = SpanNode("err", 12, {"name": "err", "status": "error"})
inner = SpanNode("inner", 13, {"name": "inner"})
job.add_child(ok_step)
job.add_child(err)
err.add_child(inner)

assert sorted(d.name for d in job.descendants()) == ["err", "inner", "ok1"]
assert job.matches({"no_descendant_has": [{"status": "error"}]}) is False
assert job.matches({"some_descendant_has": [{"status": "error"}]})
assert job.matches({"all_descendants_have": [{"status": "error"}]}) is False

# first condition passes, second must not see an empty walk
assert not job.matches(
    {"all_descendants_have": [{"name": "x"}], "no_descendant_has": [{"status": "error"}]}
)

# prune cuts the err subtree so the error span is invisible
assert job.matches(
    {"no_descendant_has": [{"status": "error"}], "stop_recursing_when": {"status": "error"}}
)

# empty query matches trivially; unknown attrs never match
assert job.matches({})
assert not job.matches({"some_ancestor_has": [{"status": "error"}]})

# shared-node diamond: one child object under two parents walks twice
dag_root = SpanNode("dr", 20, {"name": "dr"})
l = SpanNode("l", 21, {"name": "l"})
r = SpanNode("r", 22, {"name": "r"})
shared = SpanNode("shared", 23, {"name": "shared"})
dag_root.add_child(l)
dag_root.add_child(r)
l.add_child(shared)
r.add_child(shared)
assert [d.name for d in dag_root.descendants()].count("shared") == 2
assert dag_root.matches({"some_descendant_has": [{"name": "shared"}]})
assert not dag_root.matches({"all_descendants_have": [{"name": "shared"}]})

print("iss_pydantic__pydantic-ai__7484 ref OK")
