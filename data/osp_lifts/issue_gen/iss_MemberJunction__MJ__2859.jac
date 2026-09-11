"""MemberJunction/MJ#2859 — metadata dependency graph query API (OSP)."""

obj MetadataGraph {
    has stamp: int = 0;
}

node MetaEntity {
    has entity_id: str;
    has kind: str = "artifact";
}

edge DependsOn {}

walker DependsWalk {
    has start: str;
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can begin with Root entry {
        for e in [-->][?:MetaEntity] {
            if e.entity_id == self.start {
                visit [e];
            }
        }
    }

    can step with MetaEntity entry {
        if here.entity_id in self.claimed {
            skip;
        }
        self.claimed[here.entity_id] = True;
        if here.entity_id != self.start {
            self.reached.append(here.entity_id);
        }
        visit [here->:DependsOn:->][?:MetaEntity];
    }

    can finish with Root exit {
        report self.reached;
    }
}

walker DependentsWalk {
    has start: str;
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can begin with Root entry {
        for e in [-->][?:MetaEntity] {
            if e.entity_id == self.start {
                visit [e];
            }
        }
    }

    can step with MetaEntity entry {
        if here.entity_id in self.claimed {
            skip;
        }
        self.claimed[here.entity_id] = True;
        if here.entity_id != self.start {
            self.reached.append(here.entity_id);
        }
        visit [here<-:DependsOn:<-][?:MetaEntity];
    }

    can finish with Root exit {
        report self.reached;
    }
}

walker PathWalk {
    has src: str;
    has dst: str;
    has parent: dict[str, str] = {};
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    can begin with Root entry {
        for e in [-->][?:MetaEntity] {
            if e.entity_id == self.src {
                self.claimed[self.src] = True;
                if self.src == self.dst {
                    self.found = True;
                    disengage;
                }
                visit [e];
            }
        }
    }

    can step with MetaEntity entry {
        if self.found {
            skip;
        }
        for nxt in [here->:DependsOn:->][?:MetaEntity] {
            if nxt.entity_id in self.claimed {
                skip;
            }
            self.claimed[nxt.entity_id] = True;
            self.parent[nxt.entity_id] = here.entity_id;
            if nxt.entity_id == self.dst {
                self.found = True;
                disengage;
            }
            visit [nxt];
        }
    }
}

def _wire(
    entities: list[tuple[str, str]],
    edges: list[tuple[str, str]],
) {
    mp: dict[str, MetaEntity] = {};
    for (eid, kind) in entities {
        if eid not in mp {
            e = MetaEntity(entity_id=eid, kind=kind);
            root ++> e;
            mp[eid] = e;
        }
    }
    for (src, dst) in edges {
        a = mp.get(src, None);
        b = mp.get(dst, None);
        if a is not None and b is not None {
            a +>:DependsOn:+> b;
        }
    }
}

def _entity(eid: str) -> MetaEntity | None {
    for e in [-->][?:MetaEntity] {
        if e.entity_id == eid {
            return e;
        }
    }
    return None;
}

def _rebuild_path(parent: dict[str, str], src: str, dst: str) -> list[str] | None {
    rev: list[str] = [];
    cur = dst;
    while True {
        rev.append(cur);
        if cur == src {
            break;
        }
        nxt = parent.get(cur, "");
        if nxt == "" {
            return None;
        }
        cur = nxt;
    }
    out: list[str] = [];
    i = len(rev) - 1;
    while i >= 0 {
        out.append(rev[i]);
        i -= 1;
    }
    return out;
}

def load_graph(
    entities: list[tuple[str, str]],
    edges: list[tuple[str, str]],
) -> MetadataGraph {
    _wire(entities, edges);
    return MetadataGraph(stamp=1);
}

def dependencies(g: MetadataGraph, entity_id: str) -> list[str] {
    _ = g;
    if _entity(entity_id) is None {
        return [];
    }
    w = root spawn DependsWalk(start=entity_id, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def dependents(g: MetadataGraph, entity_id: str) -> list[str] {
    _ = g;
    if _entity(entity_id) is None {
        return [];
    }
    w = root spawn DependentsWalk(start=entity_id, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def path_between(
    g: MetadataGraph, src: str, dst: str,
) -> list[str] | None {
    _ = g;
    if _entity(src) is None or _entity(dst) is None {
        return None;
    }
    if src == dst {
        return [src];
    }
    w = root spawn PathWalk(
        src=src, dst=dst, parent={}, claimed={}, found=False,
    );
    if not w.found {
        return None;
    }
    return _rebuild_path(w.parent, src, dst);
}

def would_break(g: MetadataGraph, entity_id: str) -> list[str] {
    return dependents(g, entity_id);
}

def affected_by(g: MetadataGraph, changed: list[str]) -> list[str] {
    out: dict[str, bool] = {};
    for cid in changed {
        for d in would_break(g, cid) {
            out[d] = True;
        }
    }
    return sorted(out.keys());
}
