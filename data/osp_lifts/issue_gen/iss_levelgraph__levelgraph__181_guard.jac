"""levelgraph/levelgraph#181 — graph traversal, path, and query helpers."""

node Store {
    has sid: str;
}

node LGNode {
    has cid: str;
    has label: str = "";
}

edge Member {}
edge Down {}

def make_store() -> Store {
    st = Store(sid="lg");
    root ++> st;
    return st;
}

def put_node(st: Store, node_id: str, label: str = "") -> None {
    nd = LGNode(cid=node_id, label=label);
    st +>:Member:+> nd;
    root ++> nd;
}

def link(st: Store, parent_id: str, child_id: str) -> None {
    p = find_node(st, parent_id);
    c = find_node(st, child_id);
    if p is not None and c is not None {
        p +>:Down:+> c;
    }
}

def find_node(st: Store, node_id: str) -> LGNode | None {
    for m in [st ->:Member:->][?:LGNode] {
        if m.cid == node_id {
            return m;
        }
    }
    return None;
}

def descendants(st: Store, node_id: str, max_depth: int | None = None) -> list[tuple[str, int]] {
    nd = find_node(st, node_id);
    if nd is None {
        out: list[tuple[str, int]] = [];
        return out;
    }
    claimed: dict[str, bool] = {};
    depth_of: dict[str, int] = {};
    depth_of[node_id] = 0;
    found: list[tuple[str, int]] = [];
    w = nd spawn DescendWalk(
        claimed=claimed,
        max_depth=max_depth,
        found=found,
        depth_of=depth_of
    );
    return found;
}

def ancestors(st: Store, node_id: str, max_depth: int | None = None) -> list[tuple[str, int]] {
    nd = find_node(st, node_id);
    if nd is None {
        out: list[tuple[str, int]] = [];
        return out;
    }
    claimed: dict[str, bool] = {};
    depth_of: dict[str, int] = {};
    depth_of[node_id] = 0;
    found: list[tuple[str, int]] = [];
    w = nd spawn AscendWalk(
        claimed=claimed,
        max_depth=max_depth,
        found=found,
        depth_of=depth_of
    );
    return found;
}

def shortest_path(st: Store, from_id: str, to_id: str) -> list[str] | None {
    start = find_node(st, from_id);
    end = find_node(st, to_id);
    if start is None or end is None {
        return None;
    }
    if from_id == to_id {
        one: list[str] = [from_id];
        return one;
    }
    claimed: dict[str, bool] = {};
    parent_map: dict[str, str | None] = {};
    parent_map[from_id] = None;
    w = start spawn PathBfs(target=to_id, claimed=claimed, parent_map=parent_map);
    if not w.hit {
        return None;
    }
    return rebuild_path(parent_map, to_id, from_id);
}

def bfs_nodes(st: Store, start_id: str) -> list[str] {
    nd = find_node(st, start_id);
    if nd is None {
        empty: list[str] = [];
        return empty;
    }
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    w = nd spawn CollectBfs(claimed=claimed, order=order);
    return order;
}

def dfs_nodes(st: Store, start_id: str) -> list[str] {
    nd = find_node(st, start_id);
    if nd is None {
        empty: list[str] = [];
        return empty;
    }
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    w = nd spawn CollectDfs(claimed=claimed, order=order);
    return order;
}

def query_and(result_a: list[str], result_b: list[str]) -> list[str] {
    bset: dict[str, bool] = {};
    for x in result_b {
        bset[x] = True;
    }
    out: list[str] = [];
    for x in result_a {
        if x in bset {
            out.append(x);
        }
    }
    return out;
}

def query_or(result_a: list[str], result_b: list[str]) -> list[str] {
    seen: dict[str, bool] = {};
    out: list[str] = [];
    merged: list[str] = [];
    for x in result_a {
        merged.append(x);
    }
    for x in result_b {
        merged.append(x);
    }
    for x in merged {
        if x not in seen {
            seen[x] = True;
            out.append(x);
        }
    }
    return out;
}

def rebuild_path(parent_map: dict[str, str | None], end_id: str, start_id: str) -> list[str] {
    path: list[str] = [];
    cur: str | None = end_id;
    while cur is not None {
        path.append(cur);
        if cur == start_id {
            break;
        }
        if cur in parent_map {
            cur = parent_map[cur];
        } else {
            cur = None;
        }
    }
    rev: list[str] = [];
    i = len(path) - 1;
    while i >= 0 {
        rev.append(path[i]);
        i -= 1;
    }
    return rev;
}

walker DescendWalk {
    has claimed: dict[str, bool] = {};
    has max_depth: int | None = None;
    has found: list[tuple[str, int]] = [];
    has depth_of: dict[str, int] = {};

    can step with LGNode entry {
        print(f"descend {here.cid} depth {self.depth_of[here.cid]}");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        d = self.depth_of[here.cid];
        if self.max_depth is not None and d > self.max_depth {
            disengage;
        }
        self.found.append((here.cid, d));
        kids: list[LGNode] = [];
        for ch in [here ->:Down:->][?:LGNode] {
            kids.append(ch);
            if ch.cid not in self.depth_of {
                self.depth_of[ch.cid] = d + 1;
            }
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker AscendWalk {
    has claimed: dict[str, bool] = {};
    has max_depth: int | None = None;
    has found: list[tuple[str, int]] = [];
    has depth_of: dict[str, int] = {};

    can step with LGNode entry {
        print(f"ascend {here.cid} depth {self.depth_of[here.cid]}");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        d = self.depth_of[here.cid];
        if self.max_depth is not None and d > self.max_depth {
            disengage;
        }
        self.found.append((here.cid, d));
        pars: list[LGNode] = [];
        for p in [here <-:Down:<-][?:LGNode] {
            pars.append(p);
            if p.cid not in self.depth_of {
                self.depth_of[p.cid] = d + 1;
            }
        }
        if pars {
            visit pars;
        } else {
            disengage;
        }
    }
}

walker PathBfs {
    has target: str;
    has claimed: dict[str, bool] = {};
    has parent_map: dict[str, str | None] = {};
    has hit: bool = False;

    can step with LGNode entry {
        print(f"pathbfs {here.cid}");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.hit = True;
            disengage;
        }
        kids: list[LGNode] = [];
        for ch in [here ->:Down:->][?:LGNode] {
            kids.append(ch);
            if ch.cid not in self.parent_map {
                self.parent_map[ch.cid] = here.cid;
            }
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker CollectBfs {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with LGNode entry {
        print(f"bfs {here.cid}");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids: list[LGNode] = [];
        for ch in [here ->:Down:->][?:LGNode] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker CollectDfs {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with LGNode entry {
        print(f"dfs {here.cid}");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids: list[LGNode] = [];
        for ch in [here ->:Down:->][?:LGNode] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

"""levelgraph/levelgraph#181 — graph traversal, path, and query helpers."""

node Store {
    has sid: str;
}

node LGNode {
    has cid: str;
    has label: str = "";
}

edge Member {}
edge Down {}

def make_store() -> Store {
    st = Store(sid="lg");
    root ++> st;
    return st;
}

def put_node(st: Store, node_id: str, label: str = "") -> None {
    nd = LGNode(cid=node_id, label=label);
    st +>:Member:+> nd;
    root ++> nd;
}

def link(st: Store, parent_id: str, child_id: str) -> None {
    p = find_node(st, parent_id);
    c = find_node(st, child_id);
    if p is not None and c is not None {
        p +>:Down:+> c;
    }
}

def find_node(st: Store, node_id: str) -> LGNode | None {
    for m in [st ->:Member:->][?:LGNode] {
        if m.cid == node_id {
            return m;
        }
    }
    return None;
}

def descendants(st: Store, node_id: str, max_depth: int | None = None) -> list[tuple[str, int]] {
    nd = find_node(st, node_id);
    if nd is None {
        out: list[tuple[str, int]] = [];
        return out;
    }
    claimed: dict[str, bool] = {};
    depth_of: dict[str, int] = {};
    depth_of[node_id] = 0;
    found: list[tuple[str, int]] = [];
    w = nd spawn DescendWalk(
        claimed=claimed,
        max_depth=max_depth,
        found=found,
        depth_of=depth_of
    );
    return found;
}

def ancestors(st: Store, node_id: str, max_depth: int | None = None) -> list[tuple[str, int]] {
    nd = find_node(st, node_id);
    if nd is None {
        out: list[tuple[str, int]] = [];
        return out;
    }
    claimed: dict[str, bool] = {};
    depth_of: dict[str, int] = {};
    depth_of[node_id] = 0;
    found: list[tuple[str, int]] = [];
    w = nd spawn AscendWalk(
        claimed=claimed,
        max_depth=max_depth,
        found=found,
        depth_of=depth_of
    );
    return found;
}

def shortest_path(st: Store, from_id: str, to_id: str) -> list[str] | None {
    start = find_node(st, from_id);
    end = find_node(st, to_id);
    if start is None or end is None {
        return None;
    }
    if from_id == to_id {
        one: list[str] = [from_id];
        return one;
    }
    claimed: dict[str, bool] = {};
    parent_map: dict[str, str | None] = {};
    parent_map[from_id] = None;
    w = start spawn PathBfs(target=to_id, claimed=claimed, parent_map=parent_map);
    if not w.hit {
        return None;
    }
    return rebuild_path(parent_map, to_id, from_id);
}

def bfs_nodes(st: Store, start_id: str) -> list[str] {
    nd = find_node(st, start_id);
    if nd is None {
        empty: list[str] = [];
        return empty;
    }
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    w = nd spawn CollectBfs(claimed=claimed, order=order);
    return order;
}

def dfs_nodes(st: Store, start_id: str) -> list[str] {
    nd = find_node(st, start_id);
    if nd is None {
        empty: list[str] = [];
        return empty;
    }
    claimed: dict[str, bool] = {};
    order: list[str] = [];
    w = nd spawn CollectDfs(claimed=claimed, order=order);
    return order;
}

def query_and(result_a: list[str], result_b: list[str]) -> list[str] {
    bset: dict[str, bool] = {};
    for x in result_b {
        bset[x] = True;
    }
    out: list[str] = [];
    for x in result_a {
        if x in bset {
            out.append(x);
        }
    }
    return out;
}

def query_or(result_a: list[str], result_b: list[str]) -> list[str] {
    seen: dict[str, bool] = {};
    out: list[str] = [];
    merged: list[str] = [];
    for x in result_a {
        merged.append(x);
    }
    for x in result_b {
        merged.append(x);
    }
    for x in merged {
        if x not in seen {
            seen[x] = True;
            out.append(x);
        }
    }
    return out;
}

def rebuild_path(parent_map: dict[str, str | None], end_id: str, start_id: str) -> list[str] {
    path: list[str] = [];
    cur: str | None = end_id;
    while cur is not None {
        path.append(cur);
        if cur == start_id {
            break;
        }
        if cur in parent_map {
            cur = parent_map[cur];
        } else {
            cur = None;
        }
    }
    rev: list[str] = [];
    i = len(path) - 1;
    while i >= 0 {
        rev.append(path[i]);
        i -= 1;
    }
    return rev;
}

walker DescendWalk {
    has claimed: dict[str, bool] = {};
    has max_depth: int | None = None;
    has found: list[tuple[str, int]] = [];
    has depth_of: dict[str, int] = {};

    can step with LGNode entry {
        print(f"descend {here.cid} depth {self.depth_of[here.cid]}");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        d = self.depth_of[here.cid];
        if self.max_depth is not None and d > self.max_depth {
            disengage;
        }
        self.found.append((here.cid, d));
        kids: list[LGNode] = [];
        for ch in [here ->:Down:->][?:LGNode] {
            kids.append(ch);
            if ch.cid not in self.depth_of {
                self.depth_of[ch.cid] = d + 1;
            }
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker AscendWalk {
    has claimed: dict[str, bool] = {};
    has max_depth: int | None = None;
    has found: list[tuple[str, int]] = [];
    has depth_of: dict[str, int] = {};

    can step with LGNode entry {
        print(f"ascend {here.cid} depth {self.depth_of[here.cid]}");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        d = self.depth_of[here.cid];
        if self.max_depth is not None and d > self.max_depth {
            disengage;
        }
        self.found.append((here.cid, d));
        pars: list[LGNode] = [];
        for p in [here <-:Down:<-][?:LGNode] {
            pars.append(p);
            if p.cid not in self.depth_of {
                self.depth_of[p.cid] = d + 1;
            }
        }
        if pars {
            visit pars;
        } else {
            disengage;
        }
    }
}

walker PathBfs {
    has target: str;
    has claimed: dict[str, bool] = {};
    has parent_map: dict[str, str | None] = {};
    has hit: bool = False;

    can step with LGNode entry {
        print(f"pathbfs {here.cid}");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.hit = True;
            disengage;
        }
        kids: list[LGNode] = [];
        for ch in [here ->:Down:->][?:LGNode] {
            kids.append(ch);
            if ch.cid not in self.parent_map {
                self.parent_map[ch.cid] = here.cid;
            }
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker CollectBfs {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with LGNode entry {
        print(f"bfs {here.cid}");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids: list[LGNode] = [];
        for ch in [here ->:Down:->][?:LGNode] {
            kids.append(ch);
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

walker CollectDfs {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with LGNode entry {
        print(f"dfs {here.cid}");
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids: list[LGNode] = [];
        for ch in [here ->:Down:->][?:LGNode] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def levels_from(pairs: list[tuple[str, int]]) -> dict[str, int] {
    out: dict[str, int] = {};
    for pr in pairs {
        out[pr[0]] = pr[1];
    }
    return out;
}

def build_path_fixture() -> Store {
    st = make_store();
    put_node(st, "a");
    put_node(st, "b");
    put_node(st, "c");
    put_node(st, "d");
    link(st, "a", "b");
    link(st, "b", "c");
    link(st, "a", "d");
    link(st, "b", "d");
    return st;
}

def build_bfs_fixture() -> Store {
    st = make_store();
    put_node(st, "r");
    put_node(st, "x");
    put_node(st, "y");
    put_node(st, "z");
    link(st, "r", "x");
    link(st, "r", "y");
    link(st, "x", "z");
    return st;
}

test "shortest_path_and_level_tracking" {
    st = build_path_fixture();
    assert shortest_path(st, "a", "c") == ["a", "b", "c"];;
    assert shortest_path(st, "a", "a") == ["a"];;
    assert shortest_path(st, "missing", "c") is None;;
    levels = levels_from(ancestors(st, "c"));
    assert levels["c"] == 0;;
    assert levels["b"] == 1;;
    assert levels["a"] == 2;;
    shallow = descendants(st, "a", max_depth=1);
    shallow_ids: list[str] = [];
    for pr in shallow {
        shallow_ids.append(pr[0]);
    }
    assert shallow_ids == ["a", "b", "d"];;
}

test "bfs_dfs_order_and_query_ops" {
    st = build_bfs_fixture();
    assert bfs_nodes(st, "r") == ["r", "x", "y", "z"];;
    assert dfs_nodes(st, "r") == ["r", "x", "z", "y"];;
    left = bfs_nodes(st, "r");
    right: list[str] = ["y", "z"];
    assert query_and(left, right) == ["y", "z"];;
    assert query_or(["x"], ["y", "x"]) == ["x", "y"];;
}

test "find_node_and_unknown_start" {
    st = build_bfs_fixture();
    hit = find_node(st, "z");
    assert hit is not None;;
    assert hit.cid == "z";;
    assert bfs_nodes(st, "nope") == [];;
    assert ancestors(st, "nope") == [];;
}

test "descendants_depth_map" {
    st = build_path_fixture();
    levels = levels_from(descendants(st, "a"));
    assert levels["a"] == 0;;
    assert levels["b"] == 1;;
    assert levels["c"] == 2;;
    assert levels["d"] == 1;;
}

test "shortest_path_unreachable" {
    st = make_store();
    put_node(st, "p");
    put_node(st, "q");
    assert shortest_path(st, "p", "q") is None;;
}
