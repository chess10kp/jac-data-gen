"""Federation read-path graph traversal — gaiaaiagent/koi-processor#10."""

node Entity {
    has eid: str;
    has peer: str = "local";
}

edge Rel {}
edge PeerBridge {}

walker NeighborhoodWalk {
    has claimed: dict[str, bool] = {};
    has depth: int = 0;
    has max_depth: int = 0;
    has cap: int = 0;
    has direction: str = "out";
    has follow_peers: bool = False;
    has out: list[str] = [];
    has found: list[str] = [];

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print(["NeighborhoodWalk", here.eid, self.depth]);
        if self.depth > 0 and len(self.out) < self.cap {
            self.out.append(here.eid);
        }
        if self.depth >= self.max_depth {
            disengage;
        }
        if len(self.out) >= self.cap {
            disengage;
        }
        kids: list[Entity] = [];
        if self.direction == "out" or self.direction == "both" {
            for ch in [here ->:Rel:->][?:Entity] {
                kids.append(ch);
            }
            if self.follow_peers {
                for ch in [here ->:PeerBridge:->][?:Entity] {
                    kids.append(ch);
                }
            }
        }
        if self.direction == "in" or self.direction == "both" {
            for ch in [here <-:Rel:<-][?:Entity] {
                kids.append(ch);
            }
        }
        if not kids {
            disengage;
        }
        for kid in kids {
            self.depth = self.depth + 1;
            visit [kid];
            self.depth = self.depth - 1;
        }
        self.found = self.out;
    }
}

walker ShortestPathWalk {
    has claimed: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has target: str = "";
    has found: list[str] | None = None;

    can expand with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print(["ShortestPathWalk", here.eid]);
        if here.eid == self.target {
            self.found = reconstruct_path(self.parent, self.target);
            disengage;
        }
        kids: list[Entity] = [];
        for ch in [here ->:Rel:->][?:Entity] {
            kids.append(ch);
        }
        for ch in [here ->:PeerBridge:->][?:Entity] {
            kids.append(ch);
        }
        if not kids {
            disengage;
        }
        for kid in kids {
            if kid.eid not in self.parent {
                self.parent[kid.eid] = here.eid;
            }
            visit [kid];
        }
    }
}

def find_entity(eid: str) -> Entity | None {
    for nd in [root -->][?:Entity] {
        if nd.eid == eid {
            return nd;
        }
    }
    return None;
}

def reconstruct_path(parent: dict[str, str], target: str) -> list[str] {
    chain: list[str] = [];
    cur: str = target;
    chain.append(cur);
    while cur in parent {
        cur = parent[cur];
        chain.append(cur);
    }
    rev: list[str] = [];
    idx: int = len(chain) - 1;
    while idx >= 0 {
        rev.append(chain[idx]);
        idx = idx - 1;
    }
    return rev;
}

def neighborhood(root_id: str, max_depth: int, cap: int, direction: str) -> list[str] {
    root_node = find_entity(root_id);
    if root_node is None {
        return [];
    }
    claimed: dict[str, bool] = {};
    out: list[str] = [];
    w = root_node spawn NeighborhoodWalk(
        claimed=claimed,
        depth=0,
        max_depth=max_depth,
        cap=cap,
        direction=direction,
        follow_peers=False,
        out=out
    );
    print(["neighborhood", root_id, w.found]);
    return w.found;
}

def shortest_path(source_id: str, target_id: str) -> list[str] | None {
    src = find_entity(source_id);
    tgt = find_entity(target_id);
    if src is None or tgt is None {
        return None;
    }
    claimed: dict[str, bool] = {};
    parent: dict[str, str] = {};
    w = src spawn ShortestPathWalk(
        claimed=claimed,
        parent=parent,
        target=target_id
    );
    print(["shortest_path", source_id, target_id, w.found]);
    return w.found;
}

def federated_neighborhood(root_id: str, max_depth: int, cap: int) -> list[str] {
    root_node = find_entity(root_id);
    if root_node is None {
        return [];
    }
    claimed: dict[str, bool] = {};
    out: list[str] = [];
    w = root_node spawn NeighborhoodWalk(
        claimed=claimed,
        depth=0,
        max_depth=max_depth,
        cap=cap,
        direction="both",
        follow_peers=True,
        out=out
    );
    print(["federated_neighborhood", root_id, w.found]);
    return w.found;
}

"""Federation read-path graph traversal — gaiaaiagent/koi-processor#10."""

node Entity {
    has eid: str;
    has peer: str = "local";
}

edge Rel {}
edge PeerBridge {}

walker NeighborhoodWalk {
    has claimed: dict[str, bool] = {};
    has depth: int = 0;
    has max_depth: int = 0;
    has cap: int = 0;
    has direction: str = "out";
    has follow_peers: bool = False;
    has out: list[str] = [];
    has found: list[str] = [];

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print(["NeighborhoodWalk", here.eid, self.depth]);
        if self.depth > 0 and len(self.out) < self.cap {
            self.out.append(here.eid);
        }
        if self.depth >= self.max_depth {
            disengage;
        }
        if len(self.out) >= self.cap {
            disengage;
        }
        kids: list[Entity] = [];
        if self.direction == "out" or self.direction == "both" {
            for ch in [here ->:Rel:->][?:Entity] {
                kids.append(ch);
            }
            if self.follow_peers {
                for ch in [here ->:PeerBridge:->][?:Entity] {
                    kids.append(ch);
                }
            }
        }
        if self.direction == "in" or self.direction == "both" {
            for ch in [here <-:Rel:<-][?:Entity] {
                kids.append(ch);
            }
        }
        if not kids {
            disengage;
        }
        for kid in kids {
            self.depth = self.depth + 1;
            visit [kid];
            self.depth = self.depth - 1;
        }
        self.found = self.out;
    }
}

walker ShortestPathWalk {
    has claimed: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has target: str = "";
    has found: list[str] | None = None;

    can expand with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        print(["ShortestPathWalk", here.eid]);
        if here.eid == self.target {
            self.found = reconstruct_path(self.parent, self.target);
            disengage;
        }
        kids: list[Entity] = [];
        for ch in [here ->:Rel:->][?:Entity] {
            kids.append(ch);
        }
        for ch in [here ->:PeerBridge:->][?:Entity] {
            kids.append(ch);
        }
        if not kids {
            disengage;
        }
        for kid in kids {
            if kid.eid not in self.parent {
                self.parent[kid.eid] = here.eid;
            }
            visit [kid];
        }
    }
}

def find_entity(eid: str) -> Entity | None {
    for nd in [root -->][?:Entity] {
        if nd.eid == eid {
            return nd;
        }
    }
    return None;
}

def reconstruct_path(parent: dict[str, str], target: str) -> list[str] {
    chain: list[str] = [];
    cur: str = target;
    chain.append(cur);
    while cur in parent {
        cur = parent[cur];
        chain.append(cur);
    }
    rev: list[str] = [];
    idx: int = len(chain) - 1;
    while idx >= 0 {
        rev.append(chain[idx]);
        idx = idx - 1;
    }
    return rev;
}

def neighborhood(root_id: str, max_depth: int, cap: int, direction: str) -> list[str] {
    root_node = find_entity(root_id);
    if root_node is None {
        return [];
    }
    claimed: dict[str, bool] = {};
    out: list[str] = [];
    w = root_node spawn NeighborhoodWalk(
        claimed=claimed,
        depth=0,
        max_depth=max_depth,
        cap=cap,
        direction=direction,
        follow_peers=False,
        out=out
    );
    print(["neighborhood", root_id, w.found]);
    return w.found;
}

def shortest_path(source_id: str, target_id: str) -> list[str] | None {
    src = find_entity(source_id);
    tgt = find_entity(target_id);
    if src is None or tgt is None {
        return None;
    }
    claimed: dict[str, bool] = {};
    parent: dict[str, str] = {};
    w = src spawn ShortestPathWalk(
        claimed=claimed,
        parent=parent,
        target=target_id
    );
    print(["shortest_path", source_id, target_id, w.found]);
    return w.found;
}

def federated_neighborhood(root_id: str, max_depth: int, cap: int) -> list[str] {
    root_node = find_entity(root_id);
    if root_node is None {
        return [];
    }
    claimed: dict[str, bool] = {};
    out: list[str] = [];
    w = root_node spawn NeighborhoodWalk(
        claimed=claimed,
        depth=0,
        max_depth=max_depth,
        cap=cap,
        direction="both",
        follow_peers=True,
        out=out
    );
    print(["federated_neighborhood", root_id, w.found]);
    return w.found;
}

test "neighborhood_out_depth_one" {
    a = Entity(eid="a");
    b = Entity(eid="b");
    c = Entity(eid="c");
    root ++> a;
    a +>:Rel:+> b;
    b +>:Rel:+> c;
    got = neighborhood("a", 1, 10, "out");
    assert got == ["b"];
}

test "neighborhood_cap_limits" {
    a = Entity(eid="a");
    b = Entity(eid="b");
    c = Entity(eid="c");
    root ++> a;
    a +>:Rel:+> b;
    a +>:Rel:+> c;
    got = neighborhood("a", 2, 1, "out");
    assert len(got) == 1;
    assert got[0] == "b" or got[0] == "c";
}

test "shortest_path_found" {
    a = Entity(eid="a");
    b = Entity(eid="b");
    c = Entity(eid="c");
    root ++> a;
    a +>:Rel:+> b;
    b +>:Rel:+> c;
    got = shortest_path("a", "c");
    assert got == ["a", "b", "c"];
}

test "shortest_path_unknown" {
    a = Entity(eid="a");
    root ++> a;
    assert shortest_path("a", "missing") is None;
    assert shortest_path("missing", "a") is None;
}

test "federated_peer_bridge" {
    a = Entity(eid="a");
    b = Entity(eid="b");
    p = Entity(eid="p");
    root ++> a;
    a +>:Rel:+> b;
    a +>:PeerBridge:+> p;
    got = federated_neighborhood("a", 1, 10);
    exp: list[str] = ["b", "p"];
    got_sorted: list[str] = sorted(got);
    assert got_sorted == sorted(exp);
}

test "neighborhood_unknown_root" {
    assert neighborhood("ghost", 1, 10, "out") == [];
}
