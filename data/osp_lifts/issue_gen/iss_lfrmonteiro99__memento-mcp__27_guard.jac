# (paste .jac above)

test "reach chain" {
    g = build_graph();
    g.add_memory("a", "alpha"); g.add_memory("b", "beta"); g.add_memory("c", "gamma");
    g.add_link("a", "b", "ref"); g.add_link("b", "c", "ref");
    assert g.reachable_from("a") == ["a", "b", "c"];
    assert g.has_cycle() is False;
}

test "cycle a-b-c-a" {
    g = build_graph();
    g.add_memory("a", "A"); g.add_memory("b", "B"); g.add_memory("c", "C");
    g.add_link("a", "b"); g.add_link("b", "c"); g.add_link("c", "a");
    assert g.has_cycle() is True;
}

test "diamond revisit adversarial" {
    g = build_graph();
    g.add_memory("top", "T"); g.add_memory("l", "L"); g.add_memory("r", "R"); g.add_memory("bot", "B");
    g.add_link("top", "l"); g.add_link("top", "r");
    g.add_link("l", "bot"); g.add_link("r", "bot");
    g.add_link("bot", "top", "back");
    assert g.has_cycle() is True;
    assert sorted(g.reachable_from("top")) == ["bot", "l", "r", "top"];
}
