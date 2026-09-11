"""EffortlessMetrics/perl-lsp-swarm#10834 — assignment receiver propagation (OSP lift)."""

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
