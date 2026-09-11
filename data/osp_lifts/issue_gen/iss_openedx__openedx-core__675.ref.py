"""Reference harness: exercises every public function of iss_openedx__openedx-core__675."""
import importlib

mod = importlib.import_module("iss_openedx__openedx-core__675")
CompetencyTree = mod.CompetencyTree
DepthError = mod.DepthError

t = CompetencyTree()
t.add_group("competency:python")
t.add_group("g:basics", parent="competency:python")
t.add_group("g:advanced", parent="competency:python")
t.add_criterion("c:variables", "g:basics")
t.add_criterion("c:loops", "g:basics")
t.add_group("g:async", parent="g:advanced")
t.add_criterion("c:eventloop", "g:async")

# Depth cap: basics(1) -> async(2); a child group at depth 3 is refused.
try:
    t.add_group("g:deep", parent="g:async")
    raise SystemExit("expected DepthError")
except DepthError:
    pass

# Criteria evaluate in insertion order within their group.
assert t.list_criteria_ordered("g:basics") == ["c:variables", "c:loops"]
assert t.list_criteria_ordered("g:advanced") == []   # groups are not criteria
assert t.live_nodes() == [
    "c:eventloop", "c:loops", "c:variables",
    "competency:python", "g:advanced", "g:async", "g:basics",
]

# No progress anywhere under g:basics -> hard delete of the whole subtree.
fate, removed = t.remove_group("g:basics")
assert fate == "deleted"
assert removed == ["c:loops", "c:variables", "g:basics"]
assert t.live_nodes() == ["c:eventloop", "competency:python", "g:advanced", "g:async"]

# Progress in ANY leaf below -> archive-only, nothing is destroyed.
t.record_progress("learner-7", "c:eventloop")
fate, removed = t.remove_group("g:advanced")
assert fate == "archived"
assert removed == ["c:eventloop", "g:advanced", "g:async"]
assert t.kind_of["c:eventloop"] == "criterion"       # data preserved
assert "g:advanced" in t.archived
assert t.progress_in_subtree("g:advanced") == ["learner-7"]
assert t.live_nodes() == ["competency:python"]

# Directed errors.
u = CompetencyTree()
u.add_group("solo")
try:
    u.remove_group("ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
u.add_criterion("c:x", "solo")
try:
    u.add_group("g:x", parent="c:x")
    raise SystemExit("expected criteria-are-leaves")
except ValueError:
    pass
try:
    u.record_progress("l1", "ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass

# Corrupt cycle in parent pointers terminates the walks.
c = CompetencyTree()
c.kind_of = {"p": "group", "q": "group"}
c.parent_of["p"] = "q"
c.parent_of["q"] = "p"
c.children_of = {"p": ["q"], "q": ["p"]}
assert sorted(c._subtree("p")) == ["p", "q"]
