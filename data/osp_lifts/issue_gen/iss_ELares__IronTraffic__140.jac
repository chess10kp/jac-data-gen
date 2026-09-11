"""OSP lift: bundle validation. Source: ELares/IronTraffic#140."""

node BundlePart {
    has name: str;
}

edge Refers {}
edge Links {}

glob BUDGET_DEFAULT: int = 8;

walker BudgetWalker {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has budget: int = 0;
    has depth: int = 0;
    has start: str = "";

    can begin with Root entry {
        for p in [-->][?:BundlePart] {
            if p.name == self.start {
                visit [p];
            }
        }
    }

    can step with BundlePart entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        if self.depth >= self.budget {
            disengage;
        }
        for nxt in [here ->:Links:->][?:BundlePart] {
            nxt spawn BudgetWalker(
                claimed=self.claimed,
                reached=self.reached,
                budget=self.budget,
                depth=self.depth + 1,
                start=self.start,
            );
        }
    }

    can finish with Root exit {
        report self.reached;
    }
}

walker CycleWalker {
    has claimed: dict[str, bool] = {};
    has on_stack: dict[str, bool] = {};
    has cycle_nodes: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for p in [-->][?:BundlePart] {
            if p.name == self.start {
                visit [p];
            }
        }
    }

    can step with BundlePart entry {
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
        visit [->:Links:->] else {
            disengage;
        }
        del self.on_stack[here.name];
    }

    can finish with Root exit {
        report self.cycle_nodes;
    }
}

def _wire_links(edges: list[tuple[str, str]]) -> dict[str, BundlePart] {
    nodes: dict[str, BundlePart] = {};
    for (a, b) in edges {
        if a not in nodes {
            nodes[a] = BundlePart(name=a);
            root ++> nodes[a];
        }
        if b not in nodes {
            nodes[b] = BundlePart(name=b);
            root ++> nodes[b];
        }
        nodes[a] +>:Links:+> nodes[b];
    }
    return nodes;
}

def resolve_refs(
    refs: list[tuple[str, str]],
    known: set[str],
) -> tuple[list[str], list[str]] {
    resolved: list[str] = [];
    dangling: list[str] = [];
    for (src, dst) in refs {
        if dst in known {
            resolved.append(f"{src}->{dst}");
        } else {
            dangling.append(dst);
        }
    }
    return (sorted(set(resolved)), sorted(set(dangling)));
}

def detect_cycles(edges: list[tuple[str, str]]) -> list[str] {
    nodes = _wire_links(edges);
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

def budgeted_reach(
    start: str,
    edges: list[tuple[str, str]],
    budget: int = BUDGET_DEFAULT,
) -> list[str] {
    nodes = _wire_links(edges);
    if start not in nodes {
        return [];
    }
    w = root spawn BudgetWalker(
        start=start,
        claimed={},
        reached=[],
        budget=budget,
        depth=0,
    );
    return sorted(w.reached);
}
