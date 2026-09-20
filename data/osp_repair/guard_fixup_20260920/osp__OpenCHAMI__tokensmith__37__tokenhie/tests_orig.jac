test "issue, inheritance, and scope degradation" {
    reg = build_registry([]);
    issue(reg, "sess", ["read", "write", "admin"], {"amr": ["pwd", "otp"], "acr": "urn:mfa:required", "auth_time": 1719708600});
    issue(reg, "api1", ["read"], None, "sess");
    issue(reg, "short", ["admin"], {"acr": "urn:mfa:required"}, "sess");
    assert effective_claims(reg, "api1")["acr"] == "urn:mfa:required";
    assert effective_claims(reg, "api1")["amr"] == ["pwd", "otp"];
    assert effective_claims(reg, "sess")["acr"] == "urn:mfa:required";
    try {
        issue(reg, "bad", ["sudo"], None, "api1");
        assert False, "expected elevation error";
    } except ValueError {
        assert True;
    }
}

test "revoke cascade kills descendants not siblings" {
    reg = build_registry([]);
    issue(reg, "sess", ["read"]);
    issue(reg, "a", ["read"], None, "sess");
    issue(reg, "b", ["read"], None, "sess");
    issue(reg, "a1", ["read"], None, "a");
    assert revoke(reg, "a") == ["a", "a1"];
    assert not is_active(reg, "a1");
    assert is_active(reg, "b");
    assert is_active(reg, "sess");
    try {
        revoke(reg, "a");
        assert False, "expected already-revoked error";
    } except ValueError {
        assert True;
    }
}

test "deep chain root revocation and postcondition" {
    reg = build_registry([("t0", ["read"])]);
    for i in [1, 2, 3, 4] {
        pid = "t" + str(i - 1);
        issue(reg, "t" + str(i), ["read"], None, pid);
    }
    assert is_active(reg, "t4");
    assert revoke(reg, "t0") == ["t0", "t1", "t2", "t3", "t4"];
    for i in [0, 1, 2, 3, 4] {
        assert not is_active(reg, "t" + str(i));
    }
}

test "adversarial diamond revokes once-only via shared child" {
    reg = build_registry([("top", ["read"]), ("l", ["read"]), ("r", ["read"])]);
    tn = reg.resolve("top");
    ln = reg.resolve("l");
    rn = reg.resolve("r");
    bot = TokenNode(token_id="bot", scopes=["read"]);
    root ++> bot;
    reg.tokens["bot"] = bot;
    tn +>:ChildToken:+> ln;
    tn +>:ChildToken:+> rn;
    ln +>:ChildToken:+> bot;
    rn +>:ChildToken:+> bot;
    assert revoke(reg, "top") == ["bot", "l", "r", "top"];
}

test "corrupt parent cycle terminates" {
    reg = build_registry([("x", []), ("y", [])]);
    xn = reg.resolve("x");
    yn = reg.resolve("y");
    xn +>:ChildToken:+> yn;
    yn +>:ChildToken:+> xn;
    ch = _chain(reg, "x");
    assert len(ch) == 2;  # x -> y -> x stops on revisit
    assert effective_claims(reg, "x") == {};
}

test "explicit empty values and extra keys merge nearest-wins" {
    reg = build_registry([]);
    issue(reg, "root", ["read"], {"amr": ["pwd"], "acr": "urn:a", "auth_time": 100, "org": "acme"});
    issue(reg, "mid", ["read"], {"acr": ""}, "root");
    issue(reg, "leaf", ["read"], {"auth_time": 0, "dept": "ops"}, "mid");
    eff = effective_claims(reg, "leaf");
    # explicit empties override ancestors; extra keys ride along
    assert eff["acr"] == "", eff;
    assert eff["auth_time"] == 0;
    assert eff["amr"] == ["pwd"];       # inherited untouched
    assert eff["org"] == "acme";        # inherited extra key
    assert eff["dept"] == "ops";        # own extra key
}