test "one event invalidates the downstream closure once" {
    g = build_graph([("tag", "k_tag"), ("lecture", "k_lec"), ("course", "k_course"), ("lesson", "k_les"), ("exercise", "k_ex")]);
    add_dependency(g, "lesson", "lecture");
    add_dependency(g, "lesson", "tag");
    add_dependency(g, "course", "lecture");
    add_dependency(g, "exercise", "tag");
    assert publish_change(g, "lecture") == ["k_course", "k_les"];
    assert is_stale(g, "course") and is_stale(g, "lesson");
    assert not is_stale(g, "exercise") and not is_stale(g, "lecture");
    mark_fresh(g, "lesson");
    assert not is_stale(g, "lesson");
}

test "depth-capped sweep respects the budget" {
    g = build_graph([("root", "kr"), ("mid1", "km1"), ("mid2", "km2"), ("leaf", "kl")]);
    add_dependency(g, "mid1", "root");
    add_dependency(g, "mid2", "mid1");
    add_dependency(g, "leaf", "mid2");
    assert invalidate_all_upstream_of(g, "root", 0) == [];
    assert invalidate_all_upstream_of(g, "root", 1) == ["km1"];
    assert invalidate_all_upstream_of(g, "root", 2) == ["km1", "km2"];
    for k in ["km1", "km2"] {
        g.stale.discard(k);
    }
    assert invalidate_all_upstream_of(g, "root", 10) == ["kl", "km1", "km2"];
    rev = reverse_adjacency(g);  # producer -> its direct consumers
    assert sorted(rev.keys()) == ["mid1", "mid2", "root"], rev;
    assert rev["root"] == ["mid1"] and rev["mid1"] == ["mid2"];
    assert "leaf" not in rev;  # producers without consumers stay absent
}

test "link rejection" {
    g = build_graph([("a", "ka"), ("b", "kb")]);
    try {
        add_dependency(g, "ghost", "a");
        assert False;
    } except KeyError { assert True; }
    try {
        add_dependency(g, "a", "a");
        assert False;
    } except ValueError { assert True; }
    try {
        publish_change(g, "ghost");
        assert False;
    } except KeyError { assert True; }
}

test "imported dependency cycle terminates" {
    g = build_graph([("a", "ka"), ("b", "kb")]);
    an = g.resolve("a");
    if an is None {
        assert False;
    } else {
        bn = g.resolve("b");
        if bn is None {
            assert False;
        } else {
            # a reads b AND b reads a (imported corruption)
            an +>:Feeds:+> bn;
            bn +>:Feeds:+> an;
            assert publish_change(g, "b") == ["ka"];
        }
    }
}