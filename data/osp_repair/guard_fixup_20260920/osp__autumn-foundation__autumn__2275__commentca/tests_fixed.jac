test "scoped walk vs unscoped cascade reach" {
    st = build_store();
    add_comment(st, "a1", "(ticket,A)");
    add_comment(st, "a2", "(ticket,A)", "a1");
    add_comment(st, "a3", "(ticket,A)", "a2");
    add_comment(st, "b1", "(post,B)");
    try {
        add_comment(st, "bad", "(post,B)", "a1");
        assert False, "expected cross-record reject";
    } except ValueError { assert True; }
    import_comment(st, "x1", "(post,B)", "a2");
    assert scoped_subtree(st, "a1") == ["a1", "a2", "a3"];
    assert unscoped_cascade_reach(st, "a1") == ["a1", "a2", "a3", "x1"];
    assert spill_set(st, "a1") == ["x1"];
}

test "honest delete repairs every affected counter" {
    st = build_store();
    add_comment(st, "r1", "(ticket,A)");
    add_comment(st, "r2", "(ticket,A)", "r1");
    import_comment(st, "x9", "(post,B)", "r2");
    rep = hard_delete_subtree(st, "r1");
    assert rep["scoped"] == 2;
    assert rep["total"] == 3;
    assert rep["spill"] == 1;
    assert st.counts.get("(ticket,A)", 0) == 0;
    assert st.counts.get("(post,B)", 0) == 0;   # corruption repaired
    assert len(st.comments.keys()) == 0;
}

test "clean subtree has no spill and levels pin depth" {
    st = build_store();
    add_comment(st, "c0", "(t,a)");
    for i in [1, 2, 3] {
        pid = "c" + str(i - 1);
        add_comment(st, "c" + str(i), "(t,a)", pid);
    }
    rep = hard_delete_subtree(st, "c0");
    assert rep == {"scoped": 4, "total": 4, "spill": 0, "levels": [1, 1, 1]};
    assert st.counts.get("(t,a)", 0) == 0;
}

test "adversarial diamond terminates once-only" {
    st = build_store();
    add_comment(st, "top", "(t,a)");
    add_comment(st, "l", "(t,a)", "top");
    add_comment(st, "rr", "(t,a)", "top");
    ln = st.resolve("l");
    if ln is None {
        assert False, "expected l node";
        return;
    }
    rn = st.resolve("rr");
    if rn is None {
        assert False, "expected rr node";
        return;
    }
    bot = CommentNode(cid="bot", scope="(t,a)");
    root ++> bot;
    st.comments["bot"] = bot;
    ln +>:ChildComment:+> bot;
    rn +>:ChildComment:+> bot;
    assert scoped_subtree(st, "top") == ["bot", "l", "rr", "top"];
    rep = hard_delete_subtree(st, "top");
    assert rep["total"] == 4;
}