# ipfs/kubo#4985 — pin add skips traversal under already-recursive pins

node Block {
    has cid: str;
    has links: list[str] = [];
}

edge Link {}

obj PinStore {
    has recursive: dict[str, bool] = {};
    has direct: dict[str, bool] = {};

    def is_recursive(cid: str) -> bool {
        if cid in self.recursive {
            return self.recursive[cid];
        }
        return False;
    }

    def add_recursive(cid: str) {
        self.recursive[cid] = True;
    }
}

walker PinAdd {
    has store: PinStore;
    has claimed: dict[str, bool] = {};
    has checked: list[str] = [];

    can start with Block entry {
        if here.cid in self.claimed {
            skip;
        }
        # already-recursive pin guarantees children present: prune subtree
        if here.cid != "" and self.store.is_recursive(here.cid) and len(self.checked) > 0 {
            skip;
        }
        self.claimed[here.cid] = True;
        self.checked.append(here.cid);
        kids: list[Block] = [here ->:Link:->][?:Block];
        visit kids else { disengage; }
        self.store.add_recursive(here.cid);
    }
}

def build_graph(nodes: dict[str, Block]) -> Block | None {
    # nodes pre-constructed; connect links into a fixture graph
    for cid in sorted(nodes.keys()) {
        nd = nodes[cid];
        for ch in nd.links {
            if ch in nodes {
                nd +>:Link:+> nodes[ch];
            }
        }
    }
    if len(nodes.keys()) == 0 {
        return None;
    }
    first: str = sorted(nodes.keys())[0];
    return nodes[first];
}

def pin_add(nodes: dict[str, Block], root_id: str, store: PinStore) -> dict | None {
    if root_id not in nodes {
        return None;
    }
    w = nodes[root_id] spawn PinAdd(store=store, claimed={}, checked=[]);
    return {"checked": sorted(w.checked), "pinned": root_id};
}

def pin_ls(store: PinStore) -> list[str] {
    return sorted(store.recursive.keys());
}

test "diamond revisit prunes" {
    let a = Block(cid="a", links=["b", "c"]);
    let b = Block(cid="b", links=["d"]);
    let c = Block(cid="c", links=["d"]);
    let d = Block(cid="d", links=[]);
    let nodes: dict[str, Block] = {"a": a, "b": b, "c": c, "d": d};
    build_graph(nodes);
    let st = PinStore();
    let res = pin_add(nodes, "a", st);
    assert res is not None;
    assert res["checked"] == ["a", "b", "c", "d"];;
}

test "unknown id tolerated returns None" {
    let x = Block(cid="x", links=[]);
    let nodes: dict[str, Block] = {"x": x};
    build_graph(nodes);
    let st = PinStore();
    assert pin_add(nodes, "missing", st) is None;;
}

test "pre-pinned subtree skipped" {
    let a = Block(cid="a", links=["b"]);
    let b = Block(cid="b", links=["c"]);
    let c = Block(cid="c", links=[]);
    let nodes: dict[str, Block] = {"a": a, "b": b, "c": c};
    build_graph(nodes);
    let st = PinStore();
    st.add_recursive("b");
    let res = pin_add(nodes, "a", st);
    assert res is not None;
    assert "c" not in res["checked"];;
}

test "pin_ls sorted output" {
    let st = PinStore();
    st.add_recursive("z");
    st.add_recursive("m");
    assert pin_ls(st) == ["m", "z"];;
}

test "empty graph" {
    let nodes: dict[str, Block] = {};
    assert build_graph(nodes) is None;;
}
