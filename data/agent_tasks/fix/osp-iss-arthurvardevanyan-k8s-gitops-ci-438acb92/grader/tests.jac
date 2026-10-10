import from main { ImpersonationAuditor, Rule }
test "flags unscoped user impersonation" {
    rule = Rule(
        verbs=["impersonate"],
        resources=["users"],
        resource_names=[],
        label="unscoped-users",
    );

    res = rule spawn ImpersonationAuditor();

    assert len(res.flagged) == 1, f"got {res.flagged}";
    assert res.flagged[0] == "unscoped-users", f"got {res.flagged}";
    assert len(res.allowed) == 0, f"got {res.allowed}";
    assert len(res.reports) == 1, f"got {res.reports}";
}

test "allows explicitly scoped impersonation" {
    rule = Rule(
        verbs=["impersonate"],
        resources=["users"],
        resource_names=["alice", "bob"],
        label="scoped-users",
    );

    res = rule spawn ImpersonationAuditor();

    assert len(res.flagged) == 0, f"got {res.flagged}";
    assert len(res.allowed) == 1, f"got {res.allowed}";
    assert res.allowed[0] == "scoped-users", f"got {res.allowed}";
    assert len(res.reports) == 1, f"got {res.reports}";
}

test "flags wildcard impersonation but ignores unrelated rules" {
    wildcard_rule = Rule(
        verbs=["*"],
        resources=["*"],
        resource_names=[],
        label="wildcard-all",
    );
    read_rule = Rule(
        verbs=["get", "list"],
        resources=["pods"],
        resource_names=[],
        label="read-pods",
    );

    wildcard_res = wildcard_rule spawn ImpersonationAuditor();
    read_res = read_rule spawn ImpersonationAuditor();

    assert len(wildcard_res.flagged) == 1, f"got {wildcard_res.flagged}";
    assert wildcard_res.flagged[0] == "wildcard-all", f"got {wildcard_res.flagged}";
    assert len(read_res.flagged) == 0, f"got {read_res.flagged}";
    assert len(read_res.allowed) == 1, f"got {read_res.allowed}";
    assert read_res.allowed[0] == "read-pods", f"got {read_res.allowed}";
}
