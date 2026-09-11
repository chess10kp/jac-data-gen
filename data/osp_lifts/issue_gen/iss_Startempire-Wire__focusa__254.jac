"""Startempire-Wire/focusa#254 — CallGraph frame tree with spawn reachability."""

node CallFrame {
    has name: str;
    has loaded: bool = False;
}

edge Spawns {}

edge ChildOf {}

obj CallGraphStore {
    has frames: dict[str, CallFrame] = {};
}

walker SpawnReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with CallFrame entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Spawns:->][?:CallFrame];
    }
}

def load_callgraph(
    frames: list[tuple[str, str | None]],
    spawn_edges: list[tuple[str, str]],
) -> CallGraphStore {
    g = CallGraphStore();
    for (name, parent) in frames {
        if parent is not None and g.frames.get(parent, None) is None {
            raise KeyError("unknown parent frame");
        }
        nd = CallFrame(name=name);
        root ++> nd;
        g.frames[name] = nd;
        if parent is not None {
            p = g.frames.get(parent, None);
            if p is not None { p +>:ChildOf:+> nd; }
        }
    }
    for (caller, callee) in spawn_edges {
        c = g.frames.get(caller, None);
        d = g.frames.get(callee, None);
        if c is not None and d is not None { c +>:Spawns:+> d; }
    }
    return g;
}

def ancestor_frames(store: CallGraphStore, frame: str) -> list[str] {
    nd = store.frames.get(frame, None);
    if nd is None { return []; }
    chain: list[str] = [];
    cur: CallFrame | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.name in seen { break; }
        seen[cur.name] = True;
        chain.append(cur.name);
        parent: CallFrame | None = None;
        for p in [cur <-:ChildOf:<-][?:CallFrame] {
            parent = p;
            break;
        }
        cur = parent;
    }
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

def reachable_spawns(store: CallGraphStore, `root: str) -> list[str] {
    nd = store.frames.get(`root, None);
    if nd is None { return []; }
    w = nd spawn SpawnReach(claimed={}, reached=[]);
    return sorted(w.reached);
}

def frontier_frames(store: CallGraphStore, loaded: list[str]) -> list[str] {
    for name in loaded {
        n = store.frames.get(name, None);
        if n is not None { n.loaded = True; }
    }
    out: list[str] = [];
    for name in sorted(store.frames.keys()) {
        nd = store.frames.get(name, None);
        if nd is None or nd.loaded { continue; }
        parent: CallFrame | None = None;
        for p in [nd <-:ChildOf:<-][?:CallFrame] {
            parent = p;
            break;
        }
        if parent is not None and parent.loaded { out.append(name); }
    }
    return out;
}
