"""JustAHobbyDev/more-agent-protocol#20 — Manager delegation + coord reconciliation (OSP lift)."""

obj CoordGraph {
    has nodes: dict[str, Agent] = {};
}

node Agent {
    has name: str;
}

edge Manages {}
edge Coordinates {}

walker DelegatedSubtree {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Agent entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.hits.append(here.name);
        visit [->:Manages:->][?:Agent];
    }
}

walker CoordClosure {
    has origin: str;
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Agent entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name != self.origin {
            self.hits.append(here.name);
        }
        visit [->:Coordinates:->][?:Agent];
    }
}

def build_coord_graph(
    specs: list[tuple[str, str | None, list[str]]],
) -> CoordGraph {
    g = CoordGraph();
    for (name, _mgr, _coords) in specs {
        if name not in g.nodes {
            ag = Agent(name=name);
            root ++> ag;
            g.nodes[name] = ag;
        }
    }
    for (name, mgr, coords) in specs {
        ag = g.nodes[name];
        if mgr is not None {
            par = g.nodes.get(mgr, None);
            if par is not None {
                par +>:Manages:+> ag;
            }
        }
        for tgt_name in coords {
            tgt = g.nodes.get(tgt_name, None);
            if tgt is not None {
                ag +>:Coordinates:+> tgt;
            }
        }
    }
    return g;
}

def manager_chain(g: CoordGraph, agent: str) -> list[str] {
    cur = g.nodes.get(agent, None);
    if cur is None {
        return [];
    }
    acc: list[str] = [];
    seen: dict[str, bool] = {};
    while True {
        parents = [cur <-:Manages:<-][?:Agent];
        if not parents {
            break;
        }
        par = parents[0];
        if par.name in seen {
            break;
        }
        seen[par.name] = True;
        acc.append(par.name);
        cur = par;
    }
    return acc;
}

def delegated_subtree(g: CoordGraph, manager: str) -> list[str] {
    start = g.nodes.get(manager, None);
    if start is None {
        return [];
    }
    w = start spawn DelegatedSubtree();
    return sorted(w.hits);
}

def coord_successors(g: CoordGraph, agent: str) -> list[str] {
    ag = g.nodes.get(agent, None);
    if ag is None {
        return [];
    }
    return sorted([t.name for t in [ag ->:Coordinates:->][?:Agent]]);
}

def coord_reachable(g: CoordGraph, agent: str) -> list[str] {
    start = g.nodes.get(agent, None);
    if start is None {
        return [];
    }
    w = start spawn CoordClosure(origin=agent);
    return sorted(w.hits);
}

def reconcile(g: CoordGraph, manager: str) -> list[str] {
    start = g.nodes.get(manager, None);
    if start is None {
        return [];
    }
    w = start spawn DelegatedSubtree();
    scope: dict[str, bool] = {};
    for nm in w.hits {
        scope[nm] = True;
    }
    violations: list[str] = [];
    for nm in w.hits {
        ag = g.nodes[nm];
        for tgt in [ag ->:Coordinates:->][?:Agent] {
            if tgt.name not in scope {
                violations.append(f"{nm}->{tgt.name}");
            }
        }
    }
    return sorted(violations);
}
