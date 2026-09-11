"""allanweber/cartogra#113 — Blast radius lift (OSP candidate)."""

obj BlastRadiusGraph {
    def add_dependency(upstream: str, downstream: str) -> None;
    def blast_radius(origin: str) -> list[str];
    def upstream_of(sid: str) -> list[str];
}

node Service {
    has sid: str;
}

edge Depends {}

walker BlastWalker {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can start with Root entry {
        matches = [root-->][?:Service, sid == self.origin];
        if matches {
            visit [matches[0]];
        } else {
            disengage;
        }
    }

    can step with Service entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        if here.sid != self.origin {
            self.hits.append(here.sid);
        }
        visit [-->];
    }
}

walker UpstreamWalker {
    has target: str;
    has preds: list[str] = [];

    can start with Root entry {
        visit [-->][?:Service];
    }

    can step with Service entry {
        for up in [here<--][?:Service] {
            if up in [here-->][?:Service, sid == self.target] {
                self.preds.append(up.sid);
            }
        }
        visit [-->];
    }
}

impl BlastRadiusGraph.add_dependency(upstream: str, downstream: str) -> None {
    up_list = [root-->][?:Service, sid == upstream];
    if up_list {
        up = up_list[0];
    } else {
        up = root ++> Service(sid=upstream);
    }
    down_list = [root-->][?:Service, sid == downstream];
    if down_list {
        down = down_list[0];
    } else {
        down = root ++> Service(sid=downstream);
    }
    up +>:Depends:+> down;
}

impl BlastRadiusGraph.blast_radius(origin: str) -> list[str] {
    w = root spawn BlastWalker(origin=origin);
    return sorted(w.hits);
}

impl BlastRadiusGraph.upstream_of(sid: str) -> list[str] {
    if not [root-->][?:Service, sid == sid] {
        return [];
    }
    w = root spawn UpstreamWalker(target=sid);
    return sorted(w.preds);
}
