"""Guard: iss_tox-dev__peryx__1343 candidate + hidden tests."""

# --- candidate (same as .jac) ---
# (paste full iss_tox-dev__peryx__1343.jac body above)

test "includes and acyclic closure" {
    g = IncludeGraph();
    g.add_include("base", "utils");
    g.add_include("utils", "common");
    assert g.includes_of("base") == ["utils"];
    assert g.closure("base") == ["common", "utils"];
    assert g.find_include_cycle() is None;
}

test "adversarial diamond closure" {
    g = IncludeGraph();
    g.add_include("a", "shared");
    g.add_include("b", "shared");
    g.add_include("shared", "deep");
    g.add_include("a", "deep");
    assert g.closure("a") == ["deep", "shared"];
    assert g.closure("b") == ["deep", "shared"];
}

test "include cycle detection" {
    g = IncludeGraph();
    g.add_include("a", "b");
    g.add_include("b", "c");
    g.add_include("c", "a");
    cyc = g.find_include_cycle();
    assert cyc is not None;
    assert set(cyc[:-1]) == {"a", "b", "c"};
}

test "unknown alias tolerance" {
    g = IncludeGraph();
    assert g.includes_of("missing") == [];
    assert g.closure("missing") == [];
    assert g.find_include_cycle() is None;
}
