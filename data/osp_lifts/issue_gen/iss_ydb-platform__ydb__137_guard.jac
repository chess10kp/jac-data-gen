"""ydb-platform/ydb#137 — recursive CTE hierarchy from parentId/childId edges."""

node Row {
    has cid: str;
}

edge ChildOf {}

walker DescendantWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can collect with Row entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print({"walk": here.cid, "origin": self.origin});
        kids: list[Row] = [];
        for ch in [here ->:ChildOf:->][?:Row] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has pairs: list[tuple[str, str]] = [];
    has origin: str = "";

    can expand with Row entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid != self.origin {
            self.pairs.append((self.origin, here.cid));
        }
        print({"from": self.origin, "at": here.cid});
        kids: list[Row] = [];
        for ch in [here ->:ChildOf:->][?:Row] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def ensure_row(index: dict[str, Row], cid: str) -> Row {
    if cid in index {
        return index[cid] as Row;
    }
    nd = Row(cid=cid);
    root ++> nd;
    index[cid] = nd;
    return nd;
}

def materialize(edges: list[tuple[str, str]]) -> dict[str, Row] {
    index: dict[str, Row] = {};
    for pair in edges {
        parent_id = pair[0];
        child_id = pair[1];
        parent_nd = ensure_row(index, parent_id);
        child_nd = ensure_row(index, child_id);
        parent_nd +>:ChildOf:+> child_nd;
    }
    return index;
}

def list_descendants(root_id: str, edges: list[tuple[str, str]]) -> list[str] {
    index = materialize(edges);
    if root_id not in index {
        return [];
    }
    start = index[root_id] as Row;
    w = start spawn DescendantWalker(claimed={}, found=[], origin=root_id);
    out: list[str] = [];
    for cid in w.found {
        out.append(cid);
    }
    out.sort();
    return out;
}

def transitive_closure(edges: list[tuple[str, str]]) -> list[tuple[str, str]] {
    index = materialize(edges);
    keys: list[str] = [];
    for k in index {
        keys.append(k);
    }
    keys.sort();
    acc: list[tuple[str, str]] = [];
    for origin_id in keys {
        start = index[origin_id] as Row;
        w = start spawn ClosureWalker(claimed={}, pairs=[], origin=origin_id);
        for pair in w.pairs {
            acc.append(pair);
        }
    }
    acc.sort();
    return acc;
}

test "descendants_tree" {
    edges: list[tuple[str, str]] = [("a", "b"), ("a", "c"), ("b", "d")];
    got = list_descendants("a", edges);
    assert got == ["a", "b", "c", "d"];
}

test "descendants_missing_root" {
    edges: list[tuple[str, str]] = [("a", "b")];
    got = list_descendants("z", edges);
    assert got == [];
}

test "descendants_cycle" {
    edges: list[tuple[str, str]] = [("a", "b"), ("b", "a"), ("b", "c")];
    got = list_descendants("a", edges);
    assert got == ["a", "b", "c"];
}

test "closure_chain" {
    edges: list[tuple[str, str]] = [("a", "b"), ("b", "c")];
    got = transitive_closure(edges);
    assert got == [("a", "b"), ("a", "c"), ("b", "c")];
}

test "closure_diamond" {
    edges: list[tuple[str, str]] = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")];
    got = transitive_closure(edges);
    assert got == [("a", "b"), ("a", "c"), ("a", "d"), ("b", "d"), ("c", "d")];
}

test "closure_cycle" {
    edges: list[tuple[str, str]] = [("x", "y"), ("y", "z"), ("z", "x")];
    got = transitive_closure(edges);
    assert got == [("x", "y"), ("x", "z"), ("y", "x"), ("y", "z"), ("z", "x"), ("z", "y")];
}
