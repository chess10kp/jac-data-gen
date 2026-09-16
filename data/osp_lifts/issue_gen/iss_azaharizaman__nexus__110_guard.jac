# azaharizaman/nexus#110 - Chart of Accounts REST API core (tree, path, search)
node Account {
    has code: str;
    has name: str;
    has atype: str = "asset";
    has is_active: bool = True;
    has is_system: bool = False;
}
edge CHILD_OF {}

def mk_account(code: str, name: str, atype: str) -> Account {
    return Account(code=code, name=name, atype=atype);
}

def link(parent: Account, kid: Account) {
    kid +>:CHILD_OF:+> parent;
}

def kids(acct: Account) -> list[Account] {
    return [acct <-:CHILD_OF:-];
}

def tree(acct: Account, max_depth: int) -> dict {
    # recursive hierarchy closure; claim-map lives on the walker
    w = acct spawn TreeWalker(max_depth=max_depth, depth=0, claimed={});
    return w.out;
}

walker TreeWalker {
    has max_depth: int;
    has depth: int = 0;
    has claimed: dict[str, bool];
    has out: dict = {};

    can build with Account entry {
        if here.code in self.claimed { skip; }
        self.claimed[here.code] = True;
        kids_list: list[Account] = [here <-:CHILD_OF:-];
        kid_maps: list[dict] = [];
        if self.depth < self.max_depth {
            for k in kids_list {
                sub_walker = k spawn TreeWalker(max_depth=self.max_depth, depth=self.depth + 1, claimed={});
                kid_maps.append(sub_walker.out);
            }
        }
        self.out = {
            "code": here.code,
            "name": here.name,
            "children": kid_maps,
        };
    }
}

def path_to_root(acct: Account) -> list[str] {
    # breadcrumb chain root -> node, claim-map cycle guard
    w = acct spawn PathWalker(claimed={});
    return w.chain;
}

walker PathWalker {
    has claimed: dict[str, bool];
    has chain: list[str] = [];

    can walk with Account entry {
        if here.code in self.claimed { skip; }
        self.claimed[here.code] = True;
        parents: list[Account] = [here ->:CHILD_OF:->];
        if len(parents) == 0 {
            self.chain.append(here.code);
        } else {
            sub = parents[0] spawn PathWalker(claimed={});
            for c in sub.chain { self.chain.append(c); }
            self.chain.append(here.code);
        }
    }
}

def search_accounts(root_node: Account, needle: str) -> list[str] {
    w = root_node spawn SearchWalker(needle=needle.lower(), claimed={});
    return sorted(w.hits);
}

walker SearchWalker {
    has needle: str;
    has claimed: dict[str, bool];
    has hits: list[str] = [];

    can sweep with Account entry {
        if here.code in self.claimed { skip; }
        self.claimed[here.code] = True;
        if self.needle in here.name.lower() { self.hits.append(here.code); }
        targets: list[Account] = [here <-:CHILD_OF:-];
        if len(targets) > 0 { visit targets; }
    }
}

test "kids returns children via in-edges" {
    a = mk_account("1000", "Assets", "asset");
    b = mk_account("1100", "Cash", "asset");
    c = mk_account("1200", "Receivables", "asset");
    root ++> a; root ++> b; root ++> c;
    link(a, b);
    link(a, c);
    got: list[str] = [];
    for k in kids(a) { got.append(k.code); }
    assert sorted(got) == ["1100", "1200"];
}

test "tree closure with depth limit" {
    a = mk_account("1000", "Assets", "asset");
    b = mk_account("1100", "Cash", "asset");
    c = mk_account("1110", "Petty Cash", "asset");
    link(a, b);
    link(b, c);
    t = tree(a, 1);
    assert t["code"] == "1000";
    assert len(t["children"]) == 1;
    assert t["children"][0]["code"] == "1100";
    assert len(t["children"][0]["children"]) == 0;
}

test "path_to_root chain" {
    a = mk_account("1000", "Assets", "asset");
    b = mk_account("1100", "Cash", "asset");
    link(a, b);
    assert path_to_root(b) == ["1000", "1100"];
    assert path_to_root(a) == ["1000"];
}

test "search multiset over subtree" {
    a = mk_account("1000", "Assets", "asset");
    b = mk_account("1100", "Cash on hand", "asset");
    c = mk_account("1200", "Inventory", "asset");
    d = mk_account("2100", "Cash equivalent", "liability");
    link(a, b);
    link(a, c);
    link(a, d);
    assert search_accounts(a, "cash") == ["1100", "2100"];
    assert search_accounts(a, "zzz") == [];
}

test "cycle guard survives diamond" {
    a = mk_account("1000", "Assets", "asset");
    b = mk_account("1100", "Cash", "asset");
    c = mk_account("1200", "Receivables", "asset");
    link(a, b);
    link(a, c);
    link(b, c);
    # c reachable twice; claim map must dedupe, no infinite loop
    t = tree(a, 5);
    assert t["code"] == "1000";
    got: list[str] = [];
    for cm in t["children"] { got.append(cm["code"]); }
    assert sorted(got) == ["1100", "1200"];
}
