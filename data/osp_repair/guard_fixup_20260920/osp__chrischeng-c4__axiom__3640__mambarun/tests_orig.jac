test "diamond adversarial downstream revisit multiset" {
    ids = ["apex", "left", "right", "merge"];
    edges = [
        ("right", "merge"),
        ("apex", "left"),
        ("left", "merge"),
        ("apex", "right"),
    ];
    adj = build_flow_graph(ids, edges);
    kinds = {
        "apex": "producer",
        "left": "registry",
        "right": "classifier",
        "merge": "consumer",
    };
    assert downstream_reach(adj, ["apex"]) == ["left", "merge", "right"];;
    assert downstream_reach(adj, ["left", "right"]) == ["merge"];;
    assert downstream_reach(
        adj,
        ["apex"],
        site_kinds=kinds,
        target_kinds=frozenset({"consumer", "registry"}),
    ) == ["left", "merge"];;
}

test "cycle tail reachable claim map skip" {
    adj = build_flow_graph(
        ["a", "b", "c", "d"],
        [("b", "d"), ("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert downstream_reach(adj, ["a"]) == ["b", "c", "d"];;
    assert downstream_reach(adj, ["c"]) == ["a", "b", "d"];;
}

test "unknown id tolerance seeds and phantom edges" {
    adj = build_flow_graph(
        ["solo"],
        [("solo", "phantom"), ("phantom", "solo"), ("missing", "solo")],
    );
    assert adj == {"solo": []};;
    assert downstream_reach(adj, ["ghost"]) == [];;
    assert downstream_reach(adj, ["ghost", "nope", "solo"]) == [];;
    wide = build_flow_graph(["x", "y"], [("x", "y")]);
    assert downstream_reach(wide, ["ghost", "x"]) == ["y"];;
}

test "as_int classifier isolated without route silent" {
    adj = build_flow_graph(["as_int_orphan", "dead_end"], []);
    ledger = {
        "as_int_orphan": {
            "kind": "classifier",
            "disposition": "typed_token",
            "family": "LonelyBridge",
        },
        "dead_end": {"kind": "producer", "disposition": "legacy_debt"},
    };
    kinds = {
        "as_int_orphan": "classifier",
        "dead_end": "producer",
    };
    assert audit_inventory(
        adj,
        ["as_int_orphan", "dead_end"],
        ledger,
        kinds,
        mode="typed_only",
    ) == ["legacy_debt_blocks_typed_token"];;
    assert audit_inventory(
        adj,
        ["as_int_orphan", "dead_end"],
        ledger,
        kinds,
        mode="inventory",
    ) == [];;
}

test "parent_route_chain mid cycle entry stops at revisit" {
    loop = {"x": "y", "y": "z", "z": "x"};
    assert parent_route_chain(loop, "y") == ["z", "x"];;
    assert parent_route_chain({"solo": "solo"}, "solo") == [];;
    assert parent_route_chain({}, "any") == [];;
}

test "load_ledger copies rows independently of source mutation" {
    rows = {
        "keep": {"disposition": "typed_token", "kind": "consumer"},
        "touch": {"disposition": "private_only", "reified": False},
    };
    ledger = load_ledger(["keep", "touch", "absent"], rows);
    rows["keep"]["disposition"] = "legacy_debt";
    rows["touch"]["reified"] = True;
    assert ledger["keep"]["disposition"] == "typed_token";;
    assert ledger["touch"]["reified"] == False;;
    assert ledger["absent"] == {"disposition": "needs_classification"};;
}