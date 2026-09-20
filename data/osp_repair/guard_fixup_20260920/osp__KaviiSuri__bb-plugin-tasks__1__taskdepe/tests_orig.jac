test "derived blocking is direct only" {
    b = build_board(["design", "impl", "test", "release"]);
    link(b, "design", "impl");
    link(b, "impl", "test");
    link(b, "test", "release");
    assert is_blocked(b, "impl") and is_blocked(b, "test");
    assert not is_blocked(b, "design");
    assert unresolved_blocker_count(b, "test") == 1;
    link(b, "design", "test");
    assert unresolved_blocker_count(b, "test") == 2;
}

test "complete cancel reopen sweep badges" {
    b = build_board(["design", "impl", "test", "release"]);
    link(b, "design", "impl");
    link(b, "impl", "test");
    link(b, "test", "release");
    link(b, "design", "test");
    touched = complete(b, "design");
    assert touched == {"impl": [], "test": ["impl"]};
    assert not is_blocked(b, "impl");
    assert is_blocked(b, "test");
    reopen(b, "design");
    assert is_blocked(b, "impl");
    cancel(b, "impl");
    assert is_blocked(b, "test");       # still blocked by reopened design
    complete(b, "design");
    assert not is_blocked(b, "test");
}

test "link rejection transactional" {
    b = build_board(["a", "bb", "c"]);
    link(b, "a", "bb");
    try {
        link(b, "bb", "bb");
        assert False, "self";
    } except ValueError { assert True; }
    try {
        link(b, "a", "bb");
        assert False, "dup";
    } except ValueError { assert True; }
    try {
        link(b, "ghost", "bb");
        assert False, "unknown";
    } except KeyError { assert True; }
    try {
        link(b, "bb", "a");   # closes a->bb back on itself
        assert False, "cycle";
    } except ValueError { assert True; }
    # diamond is NOT a cycle
    link(b, "bb", "c");
    try {
        link(b, "c", "a");   # a->bb->c plus c->a closes a loop
        assert False, "longer cycle";
    } except ValueError { assert True; }
}

test "resolved edge still closes cycle and badge never a status" {
    b = build_board(["x", "y", "z"]);
    add_task(b, "done_t", "done");
    link(b, "x", "y");
    link(b, "y", "z");
    complete(b, "z");
    link(b, "z", "done_t");   # resolved edge stored
    try {
        link(b, "done_t", "x");   # closes loop through terminal node
        assert False, "resolved-edge cycle";
    } except ValueError { assert True; }
    st = b.resolve("x");
    assert st.status == "todo";           # badge machinery left status alone
    assert not st.blocked_badge or is_blocked(b, "x");
}

test "adversarial diamond terminates once-only" {
    b = build_board(["top", "l", "r", "bot"]);
    # diamond via public API: two paths converge on bot
    link(b, "top", "l");
    link(b, "top", "r");
    link(b, "l", "bot");
    link(b, "r", "bot");
    # bot has two direct blockers; both nonterminal -> blocked once
    assert unresolved_blocker_count(b, "bot") == 2;
    assert is_blocked(b, "bot");
    complete(b, "top");
    assert unresolved_blocker_count(b, "bot") == 2;
}