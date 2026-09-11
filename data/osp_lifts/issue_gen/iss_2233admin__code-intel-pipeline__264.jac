"""2233admin/code-intel-pipeline#264 — snapshot-bound multi-view query index (OSP)."""

obj SnapshotIndex {
    has stamp: int = 0;
}

node View {
    has view_id: str;
}

edge Requires {}

walker AncestorWalk {
    has start: str;
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can begin with Root entry {
        for v in [-->][?:View] {
            if v.view_id == self.start {
                visit [v];
            }
        }
    }

    can step with View entry {
        if here.view_id in self.claimed {
            skip;
        }
        self.claimed[here.view_id] = True;
        for dep in [here->:Requires:->][?:View] {
            if dep.view_id != self.start {
                self.reached.append(dep.view_id);
            }
            visit [dep];
        }
    }

    can finish with Root exit {
        report self.reached;
    }
}

walker ReachWalk {
    has start: str;
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can begin with Root entry {
        for v in [-->][?:View] {
            if v.view_id == self.start {
                visit [v];
            }
        }
    }

    can step with View entry {
        if here.view_id in self.claimed {
            skip;
        }
        self.claimed[here.view_id] = True;
        self.reached.append(here.view_id);
        visit [here->:Requires:->][?:View];
    }

    can finish with Root exit {
        report self.reached;
    }
}

def _wire(views: list[str], requires: list[tuple[str, str]]) {
    mp: dict[str, View] = {};
    for vid in views {
        if vid not in mp {
            v = View(view_id=vid);
            root ++> v;
            mp[vid] = v;
        }
    }
    for (dst, src) in requires {
        d = mp.get(dst, None);
        s = mp.get(src, None);
        if d is not None and s is not None {
            d +>:Requires:+> s;
        }
    }
}

def _view(vid: str) -> View | None {
    for v in [-->][?:View] {
        if v.view_id == vid {
            return v;
        }
    }
    return None;
}

def load_index(views: list[str], requires: list[tuple[str, str]]) -> SnapshotIndex {
    _wire(views, requires);
    return SnapshotIndex(stamp=1);
}

def ancestors(idx: SnapshotIndex, view_id: str) -> list[str] {
    _ = idx;
    if _view(view_id) is None {
        return [];
    }
    w = root spawn AncestorWalk(start=view_id, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def reachable(idx: SnapshotIndex, seed: str) -> list[str] {
    _ = idx;
    if _view(seed) is None {
        return [];
    }
    w = root spawn ReachWalk(start=seed, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}
