test "close cascade reaches the whole subtree once" {
    h = build_tree(["root", "eng", "sci", "ml", "infra", "physics"], [("root", "eng"), ("root", "sci"), ("eng", "ml"), ("eng", "infra"), ("sci", "physics")]);
    assert close_queue(h, "root") == ["eng", "infra", "ml", "physics", "root", "sci"];
    assert close_queue(h, "root") == [];
    assert not is_open(h, "physics");
}

test "open rejected under closed ancestor" {
    h = build_tree(["root", "eng", "ml"], [("root", "eng"), ("eng", "ml")]);
    close_queue(h, "eng");
    try {
        open_queue(h, "ml");
        assert False, "expected admission error";
    } except ValueError { assert True; }
    assert open_queue(h, "root");   # root has no ancestors
    assert open_queue(h, "eng");
    assert open_queue(h, "ml");
}

test "foreground deletion requires fully-closed subtree" {
    h = build_tree(["r", "a", "b"], [("r", "a"), ("a", "b")]);
    try {
        delete_queue_foreground(h, "r");
        assert False, "expected open subtree rejection";
    } except AdmissionError as e {
        # the message names every still-open id in the doomed subtree
        assert str(e) == "subtree not closed: ['r', 'a', 'b']", str(e);
    }
    close_queue(h, "a");  # cascades to b
    try {
        delete_queue_foreground(h, "r");
        assert False;
    } except AdmissionError as e {
        assert str(e) == "subtree not closed: ['r']", str(e);
    }
    close_queue(h, "r");
    removed = delete_queue_foreground(h, "a");
    assert removed == ["a", "b"];
    assert sorted(descendants(h, "r")) == [];
    try {
        is_open(h, "b");
        assert False;
    } except KeyError { assert True; }
}

test "corrupt parent cycle terminates" {
    h = build_tree(["x", "y"], []);
    xn = h.resolve("x");
    yn = h.resolve("y");
    if xn is None or yn is None {
        assert False, "expected nodes x and y";
        return;
    }
    xn +>:Subqueue:+> yn;
    yn +>:Subqueue:+> xn;
    sn = _subtree_names(h, "x");
    if sn is None {
        assert False, "expected subtree for x";
        return;
    }
    assert sorted(sn) == ["x", "y"];
    w = xn spawn AncestorStates(visited={});
    assert not w.closed_ancestor;
}