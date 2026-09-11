# (paste iss_MadBomber__asgard__2.jac body above, then append:)
test "parallel waves diamond" {
    g = load_dag(["a","b","c","d"], [("a","c"),("b","c"),("c","d")]);
    assert parallel_waves(g) == [["a","b"],["c"],["d"]];
}
test "cycle blocks waves" {
    g = load_dag(["x","y"], [("x","y"),("y","x")]);
    assert has_cycle(g) is True;
    assert parallel_waves(g) is None;
}
