"""Reference harness for rec_31_bldgraph (monorepo build system).
Covers every public function incl. mutation postconditions; exit 0 on pass."""
import sys

sys.path.insert(0, "/home/jac/repos/jac_llm_data/data/osp_lifts/combo")
from rec_31_bldgraph import BuildGraph


def build():
    g = BuildGraph()
    g.add_target("app")
    g.add_target("lib", parent="app")
    g.add_target("util", parent="lib")
    g.add_target("tool", parent="app")
    g.add_source("util", "shared/math.py")
    g.add_source("tool", "shared/math.py")   # shared source
    g.add_source("lib", "lib/core.py")
    g.declare_dep("tool", "lib")
    g.declare_dep("lib", "util")
    return g


def test_add_and_lookup():
    g = build()
    assert sorted(g.targets) == ["app", "lib", "tool", "util"]
    try:
        g.add_target("app")
        raise AssertionError("expected duplicate error")
    except ValueError:
        pass


def test_touch_propagation():
    g = build()
    changed = g.touch("shared/math.py")
    # owners util+tool, transitive dependent of util is lib; tool depends on lib
    assert sorted(changed) == ["lib", "tool", "util"]
    assert g.dirty_targets() == ["app", "lib", "tool", "util"]  # ancestors added


def test_unknown_path():
    g = build()
    assert g.touch("nope.py") == []
    assert g.dirty_targets() == []


def test_cycle_safe_deps():
    g = build()
    g.declare_dep("util", "tool")  # creates cycle tool->lib->util->tool
    try:
        g.declare_dep("util", "util")
        raise AssertionError("expected self dependency error")
    except ValueError:
        pass
    assert g.transitive_deps("tool") == ["lib", "util"]
    assert g.transitive_deps("util") == ["lib", "tool"]
    # touch still terminates with the dep cycle present
    changed = g.touch("shared/math.py")
    assert sorted(changed) == ["lib", "tool", "util"]


def test_reset_and_chain():
    g = build()
    g.touch("lib/core.py")
    assert "app" in g.dirty_targets()
    g.reset_dirty()
    assert g.dirty_targets() == []
    assert g.path_to_root("util") == ["util", "lib", "app"]


test_add_and_lookup()
test_touch_propagation()
test_unknown_path()
test_cycle_safe_deps()
test_reset_and_chain()
print("rec_31 ref OK")
sys.exit(0)
