# Paste full candidate .jac above, then append tests.

test "ancestors diamond revisit" {
    root ++> (r := Entity(node_id="r"));
    r ++> (a := Entity(node_id="a"));
    a +>:Parent:+> (b := Entity(node_id="b"));
    b +>:Parent:+> (c := Entity(node_id="c"));
    c +>:Parent:+> a;  # cycle
    a +>:Parent:+> (d := Entity(node_id="d"));
    store = LineageStore();
    got = store.ancestors("d");
    assert got == ["a", "r"];
}

test "descendants multiset normalized" {
    root ++> (r := Entity(node_id="r"));
    r ++> (a := Entity(node_id="a"));
    a +>:Parent:+> (b := Entity(node_id="b"));
    b +>:Parent:+> (c := Entity(node_id="c"));
    c +>:Parent:+> a;
    a +>:Parent:+> (d := Entity(node_id="d"));
    store = LineageStore();
    got = store.descendants("r");
    assert got == sorted(["a", "b", "c", "d"]);
}

test "depth first-visit wins on cycle" {
    root ++> (r := Entity(node_id="r"));
    r ++> (a := Entity(node_id="a"));
    a +>:Parent:+> (b := Entity(node_id="b"));
    b +>:Parent:+> (c := Entity(node_id="c"));
    c +>:Parent:+> a;
    store = LineageStore();
    assert store.depth_from("r", "c") == 3;
}

test "would_cycle detects back-edge" {
    root ++> (r := Entity(node_id="r"));
    r ++> (a := Entity(node_id="a"));
    a +>:Parent:+> (d := Entity(node_id="d"));
    store = LineageStore();
    assert store.would_cycle("d", "r") is True;
}
