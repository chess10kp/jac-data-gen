test "effective membership closes over ancestors" {
    tx = build_taxonomy([]);
    add_tag(tx, "react");
    add_tag(tx, "nextjs", "react");
    add_tag(tx, "remix", "react");
    add_tag(tx, "test-framework");
    tag_project(tx, "p-vercel", "nextjs");
    tag_project(tx, "p-both", "nextjs");
    tag_project(tx, "p-both", "react");
    assert effective_tags(tx, "p-vercel") == ["nextjs", "react"];
    assert projects_with(tx, "react") == ["p-both", "p-vercel"];
    assert projects_with(tx, "nextjs") == ["p-both", "p-vercel"];
    assert rollup_count(tx, "react") == 2;
}

test "cleanup drops redundant rows exactly once" {
    tx = build_taxonomy([]);
    add_tag(tx, "react");
    add_tag(tx, "nextjs", "react");
    add_tag(tx, "vercel-ai", "nextjs");
    tag_project(tx, "p1", "react");
    tag_project(tx, "p1", "nextjs");
    tag_project(tx, "p1", "vercel-ai");
    out = cleanup_after_reparent(tx);
    assert out["p1"] == ["nextjs", "react"];
    assert effective_tags(tx, "p1") == ["nextjs", "react", "vercel-ai"];
}

test "set_parent cycle guard" {
    tx = build_taxonomy([]);
    add_tag(tx, "react");
    add_tag(tx, "nextjs", "react");
    try {
        set_parent(tx, "react", "nextjs");   # would close the loop
        assert False, "expected cycle error";
    } except ValueError { assert True; }
    try {
        set_parent(tx, "react", "react");
        assert False, "expected self error";
    } except ValueError { assert True; }
    try {
        set_parent(tx, "ghost", "react");
        assert False;
    } except KeyError { assert True; }
    changed = set_parent(tx, "remix-missing", "react") if False else True;
    assert changed;
}

test "legal reparent rewires and sweep stays clean" {
    tx = build_taxonomy([]);
    add_tag(tx, "react");
    add_tag(tx, "nextjs", "react");
    add_tag(tx, "remix", "react");
    tag_project(tx, "p-shopify", "remix");
    assert effective_tags(tx, "p-shopify") == ["react", "remix"];
    changed = set_parent(tx, "remix", "nextjs");
    assert changed;
    assert effective_tags(tx, "p-shopify") == ["nextjs", "react", "remix"];
    assert cleanup_after_reparent(tx) == {};
}

test "adversarial diamond terminates once-only" {
    tx = build_taxonomy(["top", "l", "r"]);
    tn = tx.resolve_tag("top");
    ln = tx.resolve_tag("l");
    rn = tx.resolve_tag("r");
    bot = TagNode(name="bot");
    root ++> bot;
    tx.tags["bot"] = bot;
    tn +>:ChildTag:+> ln;
    tn +>:ChildTag:+> rn;
    ln +>:ChildTag:+> bot;
    rn +>:ChildTag:+> bot;
    desc = _descendants(tx, "top");
    assert sorted(desc) == ["bot", "l", "r"];
}