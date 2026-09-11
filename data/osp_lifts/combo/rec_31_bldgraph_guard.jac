"""Guard suite for rec_31_bldgraph (behavioral tests over the OSP lift)."""
import from rec_31_bldgraph { BuildGraph }

def fresh() -> BuildGraph {
    g = BuildGraph();
    g.add_target("app");
    g.add_target("lib", parent="app");
    g.add_target("util", parent="lib");
    g.add_target("tool", parent="app");
    g.add_source("util", "shared/math.py");
    g.add_source("tool", "shared/math.py");
    g.add_source("lib", "lib/core.py");
    g.declare_dep("tool", "lib");
    g.declare_dep("lib", "util");
    return g;
}

test "happy path touch propagates to dependents and ancestors" {
    g = fresh();
    changed = g.touch("shared/math.py");
    assert sorted(changed) == ["lib", "tool", "util"];
    assert g.dirty_targets() == ["app", "lib", "tool", "util"];
}

test "unknown path is a no-op" {
    g = fresh();
    assert g.touch("missing.py") == [];
    assert g.dirty_targets() == [];
}

test "transitive dep closure multiset" {
    g = fresh();
    assert g.transitive_deps("tool") == ["lib", "util"];
    assert g.transitive_deps("util") == [];
}

test "dep cycle terminates via guard set" {
    g = fresh();
    g.declare_dep("util", "tool");  # tool -> lib -> util -> tool
    assert g.transitive_deps("util") == ["lib", "tool"];
    changed = g.touch("shared/math.py");
    assert sorted(changed) == ["lib", "tool", "util"];
}

test "shared descendant collected once only" {
    g = fresh();
    # diamond: app depends on lib and tool; both transitively reach util
    g.declare_dep("app", "lib");
    g.declare_dep("app", "tool");
    changed = g.touch("shared/math.py");
    assert len(changed) == len(set(changed));  # shared descendant once only
    assert changed == ["app", "lib", "tool", "util"];
    assert g.dirty_targets() == ["app", "lib", "tool", "util"];
}

test "reset and ancestor chain" {
    g = fresh();
    g.touch("lib/core.py");
    assert "app" in g.dirty_targets();
    g.reset_dirty();
    assert g.dirty_targets() == [];
    assert g.path_to_root("util") == ["util", "lib", "app"];
}

test "duplicate target rejected" {
    g = fresh();
    threw = False;
    try {
        g.add_target("app");
    } except ValueError as e {
        threw = True;
    }
    assert threw;
}

test "order-adversarial diamond: no branch lost on revisit" {
    g = BuildGraph();
    for t in ("a", "b", "c", "d", "e", "f") {
        g.add_target(t);
    }
    # diamond a->b->d, a->c->d, both d and f feed on e; revisits to a and e
    # are encountered while sibling branches are still queued
    g.declare_dep("f", "e");
    g.declare_dep("a", "b");
    g.declare_dep("a", "c");
    g.declare_dep("b", "d");
    g.declare_dep("c", "d");
    g.declare_dep("d", "e");
    g.add_source("e", "hot.c");
    changed = g.touch("hot.c");
    assert len(changed) == len(set(changed));
    assert changed == ["a", "b", "c", "d", "e", "f"];
    assert g.dirty_targets() == ["a", "b", "c", "d", "e", "f"];
}
