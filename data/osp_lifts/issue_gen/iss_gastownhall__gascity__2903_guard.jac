"""Guard tests for iss_gastownhall__gascity__2903.jac"""

import from iss_gastownhall__gascity__2903 {
    load_bead_graph,
    dependency_closure,
    protected_from_reap,
    idle_open_counts,
}

test "linear dependency closure" {
    g = load_bead_graph(
        {"w1": "open", "root": "closed", "base": "closed"},
        {"w1": "wisp", "root": "issue", "base": "issue"},
        [("w1", "root", "tracks"), ("root", "base", "parent-child")],
    );
    assert dependency_closure(g, "w1") == ["base", "root"];
}

test "diamond adversarial closure order" {
    # hub->left/right before left/right->cap so revisit fires early
    g = load_bead_graph(
        {"hub": "open", "left": "closed", "right": "closed", "cap": "closed"},
        {"hub": "wisp", "left": "wisp", "right": "wisp", "cap": "issue"},
        [
            ("hub", "left", "tracks"),
            ("hub", "right", "blocks"),
            ("left", "cap", "parent-child"),
            ("right", "cap", "parent-child"),
        ],
    );
    assert dependency_closure(g, "hub") == ["cap", "left", "right"];
}

test "closed target protected by open wisp" {
    g = load_bead_graph(
        {"w": "open", "t": "closed"},
        {"w": "wisp", "t": "issue"},
        [("w", "t", "tracks")],
    );
    assert protected_from_reap(g, "t");
}

test "closed target not protected when idle" {
    g = load_bead_graph(
        {"w": "closed", "t": "closed"},
        {"w": "wisp", "t": "issue"},
        [("w", "t", "tracks")],
    );
    assert not protected_from_reap(g, "t");
}

test "idle open counts by tier" {
    g = load_bead_graph(
        {"a": "open", "b": "open", "c": "closed"},
        {"a": "issue", "b": "wisp", "c": "wisp"},
        [],
    );
    assert idle_open_counts(g) == (1, 1);
}

test "cyclic deps terminate closure" {
    g = load_bead_graph(
        {"a": "open", "b": "open", "c": "open"},
        {"a": "wisp", "b": "wisp", "c": "wisp"},
        [("a", "b", "tracks"), ("b", "c", "blocks"), ("c", "a", "parent-child")],
    );
    assert dependency_closure(g, "a") == ["b", "c"];
}

test "unknown bead tolerant" {
    g = load_bead_graph({"x": "open"}, {"x": "issue"}, []);
    assert dependency_closure(g, "missing") == [];
    assert not protected_from_reap(g, "missing");
}
