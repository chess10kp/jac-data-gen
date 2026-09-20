"""azaharizaman/nexus#110 Chart of Accounts tree API lifts."""

node Account {
    has cid: str;
    has code: str;
    has name: str;
    has account_type: str;
    has is_active: bool = True;
    has is_system: bool = False;
}

edge Parent {}

obj ChartStore {
    has accounts: dict[str, Account] = {};
    has root_ids: list[str] = [];

    def create_account(
        cid: str,
        code: str,
        name: str,
        account_type: str,
        parent_id: str | None = None,
        is_active: bool = True,
        is_system: bool = False,
    ) -> Account {
        nd = Account(
            cid=cid,
            code=code,
            name=name,
            account_type=account_type,
            is_active=is_active,
            is_system=is_system,
        );
        root ++> nd;
        self.accounts[cid] = nd;
        if parent_id is None {
            self.root_ids.append(cid);
        } else {
            par = self.accounts[parent_id];
            par +>:Parent:+> nd;
        }
        return nd;
    }
}

walker ChildrenWalker {
    has out: list[dict] = [];

    can step with Account entry {
        row: dict = {};
        row["cid"] = here.cid;
        row["code"] = here.code;
        row["name"] = here.name;
        row["account_type"] = here.account_type;
        row["is_active"] = here.is_active;
        self.out.append(row);
        print {"children_visit": here.cid};
        disengage;
    }
}

walker AncestorWalker {
    has claimed: dict[str, bool] = {};
    has out: list[dict] = [];

    can step with Account entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        row: dict = {};
        row["cid"] = here.cid;
        row["code"] = here.code;
        row["name"] = here.name;
        row["account_type"] = here.account_type;
        row["is_active"] = here.is_active;
        self.out.append(row);
        print {"ancestor_visit": here.cid};
        pars: list[Account] = [here ->:Parent:->][?:Account];
        for par in pars {
            visit par;
        }
        disengage;
    }
}

walker SubtreeWalker {
    has claimed: dict[str, bool] = {};
    has out: list[Account] = [];

    can step with Account entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.out.append(here);
        print {"subtree_visit": here.cid};
        kids: list[Account] = [->:Parent:-> here][?:Account];
        for kid in kids {
            visit :0: kid;
        }
        disengage;
    }
}

walker SearchWalker {
    has query: str;
    has out: list[dict] = [];

    can step with Account entry {
        q = self.query.lower();
        hit = False;
        if q in here.code.lower() {
            hit = True;
        }
        if q in here.name.lower() {
            hit = True;
        }
        if hit {
            row: dict = {};
            row["cid"] = here.cid;
            row["code"] = here.code;
            row["name"] = here.name;
            row["account_type"] = here.account_type;
            row["is_active"] = here.is_active;
            self.out.append(row);
            print {"search_hit": here.cid};
        }
        kids: list[Account] = [->:Parent:-> here][?:Account];
        for kid in kids {
            visit kid;
        }
        disengage;
    }
}

def _account_row(nd: Account) -> dict {
    row: dict = {};
    row["cid"] = nd.cid;
    row["code"] = nd.code;
    row["name"] = nd.name;
    row["account_type"] = nd.account_type;
    row["is_active"] = nd.is_active;
    return row;
}

def _sort_rows(rows: list[dict]) -> list[dict] {
    keys: list[str] = [];
    for row in rows {
        keys.append(row["cid"] as str);
    }
    keys.sort();
    out: list[dict] = [];
    for k in keys {
        for row in rows {
            if (row["cid"] as str) == k {
                out.append(row);
            }
        }
    }
    return out;
}

def _build_subtree(store: ChartStore, cid: str, max_depth: int, depth: int) -> dict {
    nd = store.accounts[cid];
    node = _account_row(nd);
    kids: list[dict] = [];
    if max_depth == 0 or depth < max_depth {
        child_ids: list[str] = [];
        for kid_nd in [->:Parent:-> nd][?:Account] {
            child_ids.append(kid_nd.cid);
        }
        child_ids.sort();
        for kid_id in child_ids {
            kids.append(_build_subtree(store, kid_id, max_depth, depth + 1));
        }
    }
    node["children"] = kids;
    return node;
}

def get_children(store: ChartStore, account_id: str) -> list[dict] {
    if account_id not in store.accounts {
        return [];
    }
    par = store.accounts[account_id];
    kids: list[Account] = [->:Parent:-> par][?:Account];
    merged: list[dict] = [];
    for kid in kids {
        w = kid spawn ChildrenWalker();
        for row in w.out {
            merged.append(row);
        }
    }
    rows = _sort_rows(merged);
    print {"get_children": account_id, "count": len(rows)};
    return rows;
}

def get_ancestors(store: ChartStore, account_id: str) -> list[dict] {
    if account_id not in store.accounts {
        return [];
    }
    start = store.accounts[account_id];
    pars: list[Account] = [start ->:Parent:->][?:Account];
    if not pars {
        return [];
    }
    w = pars[0] spawn AncestorWalker(claimed={});
    chain: list[dict] = [];
    for row in w.out {
        chain.insert(0, row);
    }
    print {"get_ancestors": account_id, "count": len(chain)};
    return chain;
}

def get_account_path(store: ChartStore, account_id: str) -> str {
    if account_id not in store.accounts {
        return "";
    }
    crumbs: list[str] = [];
    chain = get_ancestors(store, account_id);
    for row in chain {
        crumbs.append(row["name"] as str);
    }
    crumbs.append(store.accounts[account_id].name);
    parts: list[str] = [];
    for c in crumbs {
        parts.append(c);
    }
    out = "";
    for i in range(len(parts)) {
        if i > 0 {
            out = out + " > ";
        }
        out = out + parts[i];
    }
    print {"get_account_path": account_id, "path": out};
    return out;
}

def build_account_tree(store: ChartStore, max_depth: int = 0) -> list[dict] {
    trees: list[dict] = [];
    sorted_roots: list[str] = [];
    for rid in store.root_ids {
        sorted_roots.append(rid);
    }
    sorted_roots.sort();
    for rid in sorted_roots {
        trees.append(_build_subtree(store, rid, max_depth, 0));
    }
    print {"build_account_tree": "ok", "count": len(trees)};
    return trees;
}

def search_accounts(store: ChartStore, query: str) -> list[dict] {
    if not query {
        return [];
    }
    merged: list[dict] = [];
    for rid in store.root_ids {
        nd = store.accounts[rid];
        w = nd spawn SearchWalker(query=query);
        for row in w.out {
            merged.append(row);
        }
    }
    rows = _sort_rows(merged);
    print {"search_accounts": query, "count": len(rows)};
    return rows;
}
