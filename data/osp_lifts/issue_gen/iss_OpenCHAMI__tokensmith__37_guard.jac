"""Token hierarchy: subtoken claim inheritance and revocation cascade.

OpenCHAMI/tokensmith#37 lifted to OSP: tokens become TokenNode archetypes,
parent pointers and the children adjacency map become typed ChildToken
edges. Claim inheritance is an ascent walker over the chain (nearest-wins
merge, explicit cycle guard); revocation is two-phase -- a CascadeCollect
walker with a once-only claim map gathers the set, the facade applies the
revoked flips outside the walk.
"""
node TokenNode {
    has token_id: str;
    has scopes: list[str];
    has claims: dict = {};   # FULL arbitrary claim dict, like the source
    has revoked: bool = False;
}
edge ChildToken {}

"""Registry handle: id resolution through this lookup map is domain API."""
obj Registry {
    has tokens: dict[str, TokenNode];

    def resolve(token_id: str) -> TokenNode | None {
        return self.tokens.get(token_id);
    }
}

def build_registry(roots: list[tuple[str, list[str]]]) -> Registry {
    reg = Registry(tokens={});
    for item in roots {
        t = TokenNode(token_id=item[0], scopes=item[1]);
        root ++> t;
        reg.tokens[item[0]] = t;
    }
    return reg;
}

def issue(reg: Registry, token_id: str, scopes: list[str], claims: dict | None = None, parent_id: str | None = None) {
    if parent_id is not None {
        p = reg.resolve(parent_id);
        if p is None or p.revoked {
            raise KeyError("unknown or revoked parent token");
        }
        extra: list[str] = [];
        for s in scopes {
            if s not in p.scopes {
                extra.append(s);
            }
        }
        if len(extra) > 0 {
            raise ValueError("elevated scopes");
        }
    }
    c: dict = {};
    if claims is not None {
        c = claims;
    }
    t = TokenNode(token_id=token_id, claims=c, scopes=scopes);
    root ++> t;
    reg.tokens[token_id] = t;
    if parent_id is not None {
        p2 = reg.resolve(parent_id);
        if p2 is not None {
            p2 +>:ChildToken:+> t;
        }
    }
}

"""Ascends ChildToken edges; cycle policy is the visited claim map."""
walker ChainAscent {
    has visited: dict[str, bool];
    has chain: list[TokenNode] = [];

    can step with TokenNode entry {
        if here.token_id in self.visited {
            skip;
        }
        self.visited[here.token_id] = True;
        self.chain.append(here);
        parents = [here <-:ChildToken:<-];
        if len(parents) == 0 {
            disengage;
        }
        visit [parents[0]];
    }
}

"""Nearest-first chain including self; reversed for ancestor merge order."""
def _chain(reg: Registry, token_id: str) -> list[TokenNode] | None {
    n = reg.resolve(token_id);
    if n is None {
        return None;
    }
    w = n spawn ChainAscent(visited={});
    out: list[TokenNode] = [];
    i = len(w.chain) - 1;
    while i >= 0 {
        out.append(w.chain[i]);
        i -= 1;
    }
    return out;
}

def effective_claims(reg: Registry, token_id: str) -> dict {
    # nearest-wins merge of the FULL claim dicts along the ancestor chain
    # (farthest first, self last); explicit empty values override like any
    # other value, and arbitrary extra keys ride along
    chain = _chain(reg, token_id);
    if chain is None {
        return {};
    }
    merged: dict = {};
    for node in chain {
        for k in node.claims.keys() {
            merged[k] = node.claims[k];
        }
    }
    return merged;
}

"""Gathers the cascade set over ChildToken edges; once-only claim guard."""
walker CascadeCollect {
    has claimed: dict[str, bool];
    has found: list[str] = [];

    can step with TokenNode entry {
        if here.token_id in self.claimed {
            skip;
        }
        self.claimed[here.token_id] = True;
        self.found.append(here.token_id);
        visit [->:ChildToken:->];
    }
}

def revoke(reg: Registry, token_id: str) -> list[str] {
    start = reg.resolve(token_id);
    if start is None {
        raise KeyError("unknown token");
    }
    if start.revoked {
        raise ValueError("already revoked");
    }
    # Phase 1: collect with once-only guard.
    w = start spawn CascadeCollect(claimed={});
    # Phase 2: apply outside the walk.
    for tid in w.found {
        n = reg.resolve(tid);
        if n is not None {
            n.revoked = True;
        }
    }
    return sorted(w.found);
}

def is_active(reg: Registry, token_id: str) -> bool {
    n = reg.resolve(token_id);
    if n is None {
        return False;
    }
    if n.revoked {
        return False;
    }
    chain = _chain(reg, token_id);
    if chain is None {
        return False;
    }
    for node in chain[1:] {
        if node.revoked {
            return False;
        }
    }
    return True;
}


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
