"""Reference harness: exercises every public function of iss_MaMpf-HD__mampf__863."""
import importlib

mod = importlib.import_module("iss_MaMpf-HD__mampf__863")
DependencyGraph = mod.DependencyGraph

g = DependencyGraph()
for ent, key in [("tag", "k_tag"), ("lecture", "k_lec"), ("course", "k_course"),
                 ("lesson", "k_les"), ("exercise", "k_ex"), ("sidebar", "k_side")]:
    g.register(ent, key)

# lesson reads lecture and tag; course reads lecture; sidebar reads course.
g.add_dependency("lesson", "lecture")
g.add_dependency("lesson", "tag")
g.add_dependency("course", "lecture")
g.add_dependency("sidebar", "course")
g.add_dependency("exercise", "tag")

# One event invalidates the whole downstream closure, diamond fan-out once.
keys = g.publish_change("lecture")
assert keys == ["k_course", "k_les", "k_side"]
assert g.is_stale("course") and g.is_stale("lesson") and g.is_stale("sidebar")
assert not g.is_stale("exercise")        # different branch untouched
assert not g.is_stale("lecture")         # source itself is not stale

keys = g.publish_change("tag")
assert keys == ["k_ex", "k_les"]
assert g.is_stale("exercise")

# Depth-capped sweep stops expanding past the budget.
h = DependencyGraph()
for ent in ["root", "mid1", "mid2", "leaf"]:
    h.register(ent, "k_" + ent)
h.add_dependency("mid1", "root")
h.add_dependency("mid2", "mid1")
h.add_dependency("leaf", "mid2")
assert h.invalidate_all_upstream_of("root", 0) == []
assert h.invalidate_all_upstream_of("root", 1) == ["k_mid1"]
assert h.invalidate_all_upstream_of("root", 2) == ["k_mid1", "k_mid2"]
h.stale.clear()
assert h.invalidate_all_upstream_of("root", 10) == ["k_leaf", "k_mid1", "k_mid2"]

# mark_fresh clears staleness.
g.mark_fresh("lesson")
assert not g.is_stale("lesson")

# Transactional rejection.
try:
    g.add_dependency("ghost", "tag")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
try:
    g.add_dependency("tag", "tag")
    raise SystemExit("expected self-dep reject")
except ValueError:
    pass
try:
    g.publish_change("ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass

# Imported cycle in the dependency map must terminate the BFS.
c = DependencyGraph()
c.register("a", "ka")
c.register("b", "kb")
c.depends_on["a"].add("b")
c.depends_on["b"].add("a")
assert c.publish_change("b") == ["ka"]    # visited set stops the loop
