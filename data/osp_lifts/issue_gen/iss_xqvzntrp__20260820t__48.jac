"""xqvzntrp/20260820t#48 — Composition graph (OSP lift)."""

obj ComponentGraph {
    has components: dict[str, Component] = {};
}

node Component {
    has cid: str;
    has label: str;
}

edge Composes {}

walker ChainWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Component entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.reached.append(here.cid);
        visit [->:Composes:->] else { disengage; };
    }
}

walker CycleWalk {
    has claimed: dict[str, bool] = {};
    has has_cycle: bool = False;

    can step with Component entry {
        if here.cid in self.claimed {
            self.has_cycle = True;
            skip;
        }
        self.claimed[here.cid] = True;
        visit [->:Composes:->] else { disengage; };
    }
}

def load_components(
    components: list[tuple[str, str]],
    edges: list[tuple[str, str]],
) -> ComponentGraph {
    mp: dict[str, Component] = {};
    for (cid, label) in components {
        c = Component(cid=cid, label=label);
        root ++> c;
        mp[cid] = c;
    }
    for (parent, child) in edges {
        a = mp.get(parent, None);
        b = mp.get(child, None);
        if a is not None and b is not None { a +>:Composes:+> b; }
    }
    return ComponentGraph(components=mp);
}

def composition_chain(g: ComponentGraph, `root: str) -> list[str] {
    anchor = g.components.get(`root, None);
    if anchor is None { return []; }
    w = anchor spawn ChainWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def has_composition_cycle(g: ComponentGraph, `root: str) -> bool {
    anchor = g.components.get(`root, None);
    if anchor is None { return False; }
    w = anchor spawn CycleWalk(claimed={}, has_cycle=False);
    return w.has_cycle;
}
