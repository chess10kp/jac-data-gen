"""EffortlessMetrics/perl-lsp-swarm#10834 — candidate + hidden guards."""

obj CfgStore {
    has stamp: int = 0;
    has `entry: str = "";
}

node ProgPoint {
    has pid: str;
    has recv_map: dict[str, str] = {};
    has snapshot: dict[str, str] = {};
}

edge FlowsTo {}

walker PropagateWalker {
    has claimed: dict[str, bool] = {};
    has state: dict[str, str] = {};
    has snapshots: dict[str, dict[str, str]] = {};
    has start: str = "";

    can begin with Root entry {
        for p in [-->][?:ProgPoint] {
            if p.pid == self.start { visit [p]; }
        }
    }

    can step with ProgPoint entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        for (bk, rcv) in here.recv_map.items() {
            if rcv != "" { self.state[bk] = rcv; }
        }
        self.snapshots[here.pid] = {**self.state};
        visit [->:FlowsTo:->][?:ProgPoint] else { disengage; };
    }
}

def _point(pid: str) -> ProgPoint | None {
    for p in [-->][?:ProgPoint] {
        if p.pid == pid { return p; }
    }
    return None;
}

def load_cfg(
    points: list[str],
    edges: list[tuple[str, str]],
    assignments: list[tuple[str, str, str]],
    `entry: str,
) -> CfgStore {
    mp: dict[str, ProgPoint] = {};
    for pid in points {
        if pid not in mp {
            n = ProgPoint(pid=pid);
            root ++> n;
            mp[pid] = n;
        }
    }
    for (src, dst) in edges {
        s = mp.get(src, None);
        d = mp.get(dst, None);
        if s is not None and d is not None { s +>:FlowsTo:+> d; }
    }
    for (pt, binding, receiver) in assignments {
        p = mp.get(pt, None);
        if p is not None { p.recv_map[binding] = receiver; }
    }
    return CfgStore(stamp=1, `entry=`entry);
}

def propagate_receivers(g: CfgStore) -> dict[str, dict[str, str]] {
    w = root spawn PropagateWalker(start=g.`entry, claimed={}, state={}, snapshots={});
    for (pid, snap) in w.snapshots.items() {
        pt = _point(pid);
        if pt is not None { pt.snapshot = snap; }
    }
    return w.snapshots;
}

def receivers_at(g: CfgStore, point: str, binding: str) -> str | None {
    pt = _point(point);
    if pt is None { return None; }
    if not pt.snapshot {
        propagate_receivers(g);
    }
    return pt.snapshot.get(binding, None);
}

test "perl exemplar point-specific receivers" {
    bind = "main::$x";
    g = load_cfg(
        ["entry", "after_foo_init", "call_foo", "after_bar_assign", "call_bar"],
        [
            ("entry", "after_foo_init"),
            ("after_foo_init", "call_foo"),
            ("call_foo", "after_bar_assign"),
            ("after_bar_assign", "call_bar"),
        ],
        [("after_foo_init", bind, "Foo"), ("after_bar_assign", bind, "Bar")],
        "entry",
    );
    assert receivers_at(g, "call_foo", bind) == "Foo";
    assert receivers_at(g, "call_bar", bind) == "Bar";
}

test "unknown rhs keeps prior receiver" {
    bind = "main::$x";
    g = load_cfg(
        ["entry", "keep", "query"],
        [("entry", "keep"), ("keep", "query")],
        [("keep", bind, "Foo"), ("query", bind, "")],
        "entry",
    );
    assert receivers_at(g, "query", bind) == "Foo";
}

test "binding identity shadowing" {
    g = load_cfg(
        ["entry", "inner", "exit"],
        [("entry", "inner"), ("inner", "exit")],
        [
            ("entry", "main::$x", "Foo"),
            ("entry", "main::@x", "Arr"),
            ("inner", "block::$x", "Bar"),
        ],
        "entry",
    );
    propagate_receivers(g);
    assert receivers_at(g, "exit", "main::$x") == "Foo";
    assert receivers_at(g, "exit", "main::@x") == "Arr";
    assert receivers_at(g, "exit", "block::$x") == "Bar";
}

test "diamond flow revisit once per point" {
    bind = "main::$x";
    g = load_cfg(
        ["entry", "left", "right", "join", "tail"],
        [
            ("entry", "left"),
            ("entry", "right"),
            ("left", "join"),
            ("right", "join"),
            ("join", "tail"),
        ],
        [("left", bind, "Foo"), ("right", bind, "Bar")],
        "entry",
    );
    snaps = propagate_receivers(g);
    assert "join" in snaps;
    assert receivers_at(g, "tail", bind) is not None;
    assert len(snaps) == 5;
}

test "unknown point tolerant" {
    g = load_cfg(["only"], [], [], "only");
    assert receivers_at(g, "missing", "main::$x") is None;
}
