"""Recursive reachability — ent/ent#1024 (descendants / ancestors along Follows)."""

node User {
    has uid: str;
}

edge Follows {}

node GraphHub {
    has users: dict[str, User] = {};
}

walker DescWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with User entry {
        if here.uid in self.claimed {
            skip;
        }
        self.claimed[here.uid] = True;
        if here.uid != self.origin {
            self.found.append(here.uid);
        }
        print([here.uid, self.found]);
        nxt: list[User] = [];
        for ch in [here ->:Follows:->][?:User] {
            nxt.append(ch);
        }
        if nxt {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

walker AncWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with User entry {
        if here.uid in self.claimed {
            skip;
        }
        self.claimed[here.uid] = True;
        if here.uid != self.origin {
            self.found.append(here.uid);
        }
        print([here.uid, self.found]);
        nxt: list[User] = [];
        for ch in [here <-:Follows:<-][?:User] {
            nxt.append(ch);
        }
        if nxt {
            visit :0: nxt;
        } else {
            disengage;
        }
    }
}

def ensure_user(hub: GraphHub, uid: str) -> User {
    if uid in hub.users {
        return hub.users[uid];
    }
    u = User(uid=uid);
    hub ++> u;
    hub.users[uid] = u;
    return u;
}

def create_graph() -> GraphHub {
    hub = GraphHub();
    root ++> hub;
    return hub;
}

def add_user(hub: GraphHub, uid: str) {
    ensure_user(hub, uid);
}

def add_follow_edge(hub: GraphHub, follower: str, followee: str) {
    if follower not in hub.users {
        return;
    }
    if followee not in hub.users {
        return;
    }
    src = hub.users[follower];
    dst = hub.users[followee];
    src +>:Follows:+> dst;
}

def get_descendants(hub: GraphHub, user_id: str) -> list[str] {
    if user_id not in hub.users {
        return [];
    }
    start = hub.users[user_id];
    w = start spawn DescWalker(claimed={}, found=[], origin=user_id);
    out: list[str] = w.found;
    out.sort();
    return out;
}

def get_ancestors(hub: GraphHub, user_id: str) -> list[str] {
    if user_id not in hub.users {
        return [];
    }
    start = hub.users[user_id];
    w = start spawn AncWalker(claimed={}, found=[], origin=user_id);
    out: list[str] = w.found;
    out.sort();
    return out;
}

test "descendants_chain" {
    hub = create_graph();
    add_user(hub, "a");
    add_user(hub, "b");
    add_user(hub, "c");
    add_follow_edge(hub, "a", "b");
    add_follow_edge(hub, "b", "c");
    assert get_descendants(hub, "a") == ["b", "c"];
}

test "ancestors_chain" {
    hub = create_graph();
    add_user(hub, "a");
    add_user(hub, "b");
    add_user(hub, "c");
    add_follow_edge(hub, "a", "b");
    add_follow_edge(hub, "b", "c");
    assert get_ancestors(hub, "c") == ["a", "b"];
}

test "unknown_user_empty" {
    hub = create_graph();
    assert get_descendants(hub, "missing") == [];
    assert get_ancestors(hub, "missing") == [];
}

test "origin_excluded" {
    hub = create_graph();
    add_user(hub, "a");
    add_user(hub, "b");
    add_follow_edge(hub, "a", "b");
    add_follow_edge(hub, "b", "a");
    assert get_descendants(hub, "a") == ["b"];
    assert get_ancestors(hub, "a") == ["b"];
}

test "cycle_once_only" {
    hub = create_graph();
    add_user(hub, "a");
    add_user(hub, "b");
    add_user(hub, "c");
    add_follow_edge(hub, "a", "b");
    add_follow_edge(hub, "b", "c");
    add_follow_edge(hub, "c", "a");
    assert get_descendants(hub, "a") == ["b", "c"];
    assert get_ancestors(hub, "a") == ["b", "c"];
}

test "missing_edge_endpoints" {
    hub = create_graph();
    add_user(hub, "a");
    add_follow_edge(hub, "a", "z");
    add_follow_edge(hub, "z", "a");
    assert get_descendants(hub, "a") == [];
    assert get_ancestors(hub, "a") == [];
}
