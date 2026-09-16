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
