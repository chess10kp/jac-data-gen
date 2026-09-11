"""knex/knex#6335 — recursive closure with cycle guard (OSP)."""

obj RecursiveGraph {
    has stamp: int = 0;
}

node RNode {
    has name: str;
}

edge Next {}

walker ClosureWalk {
    has start: str;
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has cycle: bool = False;

    can begin with Root entry {
        for n in [-->][?:RNode] {
            if n.name == self.start {
                visit [n];
            }
        }
    }

    can step with RNode entry {
        if here.name in self.claims {
            self.cycle = True;
            skip;
        }
        self.claims[here.name] = True;
        self.order.append(here.name);
        visit [here->:Next:->][?:RNode];
    }

    can finish with Root exit {
        report self.order;
    }
}

def _wire(nodes: list[str], edges: list[tuple[str, str]]) {
    mp: dict[str, RNode] = {};
    for nm in nodes {
        if nm not in mp {
            n = RNode(name=nm);
            root ++> n;
            mp[nm] = n;
        }
    }
    for (s, d) in edges {
        a = mp.get(s, None);
        b = mp.get(d, None);
        if a is not None and b is not None {
            a +>:Next:+> b;
        }
    }
}

def _node(name: str) -> RNode | None {
    for n in [-->][?:RNode] {
        if n.name == name {
            return n;
        }
    }
    return None;
}

def load_graph(nodes: list[str], edges: list[tuple[str, str]]) -> RecursiveGraph {
    _wire(nodes, edges);
    return RecursiveGraph(stamp=1);
}

def closure(g: RecursiveGraph, seed: str) -> list[str] | None {
    _ = g;
    if _node(seed) is None {
        return [];
    }
    w = root spawn ClosureWalk(start=seed, claimed={}, order=[], cycle=False);
    if w.cycle {
        return None;
    }
    return sorted(w.reports[0] if w.reports else []);
}

def has_cycle(g: RecursiveGraph) -> bool {
    _ = g;
    for n in [-->][?:RNode] {
        if closure(g, n.name) is None {
            return True;
        }
    }
    return False;
}
