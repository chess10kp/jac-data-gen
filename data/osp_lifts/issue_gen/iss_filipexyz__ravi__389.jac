"""OSP lift: dependency gates + cycle detect. Source: filipexyz/ravi#389."""

node Target {
    has name: str;
}

edge Requires {}

walker CycleWalker {
    has claimed: dict[str, bool] = {};
    has on_stack: dict[str, bool] = {};
    has cycle_nodes: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for t in [-->][?:Target] {
            if t.name == self.start {
                visit [t];
            }
        }
    }

    can step with Target entry {
        if here.name in self.on_stack {
            if here.name not in self.cycle_nodes {
                self.cycle_nodes.append(here.name);
            }
            skip;
        }
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.on_stack[here.name] = True;
        visit [->:Requires:->] else {
            disengage;
        }
        del self.on_stack[here.name];
    }

    can finish with Root exit {
        report self.cycle_nodes;
    }
}

def _wire(edges: list[tuple[str, str]]) -> dict[str, Target] {
    nodes: dict[str, Target] = {};
    for (a, b) in edges {
        if a not in nodes {
            nodes[a] = Target(name=a);
            root ++> nodes[a];
        }
        if b not in nodes {
            nodes[b] = Target(name=b);
            root ++> nodes[b];
        }
        nodes[a] +>:Requires:+> nodes[b];
    }
    return nodes;
}

def eligible_targets(
    nodes: list[str],
    edges: list[tuple[str, str]],
    ready: set[str],
) -> list[str] {
    preds: dict[str, list[str]] = {};
    for n in nodes {
        preds[n] = [];
    }
    for (a, b) in edges {
        if b in preds {
            preds[b].append(a);
        }
    }
    out: list[str] = [];
    for n in sorted(nodes) {
        reqs = preds.get(n, []);
        ok = True;
        for r in reqs {
            if r not in ready {
                ok = False;
            }
        }
        if ok {
            out.append(n);
        }
    }
    return out;
}

def find_cycle_nodes(edges: list[tuple[str, str]]) -> list[str] {
    nodes = _wire(edges);
    found: list[str] = [];
    seen: dict[str, bool] = {};
    for name in sorted(nodes.keys()) {
        if name in seen {
            continue;
        }
        w = root spawn CycleWalker(start=name, claimed={}, on_stack={}, cycle_nodes=[]);
        for n in (w.reports[0] if w.reports else []) {
            if n not in seen {
                seen[n] = True;
                found.append(n);
            }
        }
    }
    return sorted(found);
}
