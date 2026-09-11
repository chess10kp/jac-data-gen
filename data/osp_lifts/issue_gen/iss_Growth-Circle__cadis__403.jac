"""Agent parent-chain depth, lifted to OSP.

Agents become nodes linked by typed ParentOf edges (parent +>:ParentOf:+>
child); the while-loop pointer chase becomes a walker over the reverse
edges. Cycle policy is the issue's remediation kept explicit: a claim map
flags the first revisit (the daemon wedge was an unguarded loop) and the
iteration cap truncates runaway chains; dead ends disengage. The facade
preserves the registry API (id-keyed lookup map is domain state).
Ref: Growth-Circle/cadis#403
"""
node Agent {
    has aid: str;
}

"""parent +>:ParentOf:+> child."""
edge ParentOf {}

glob MAX_CHAIN: int = 64;

obj Agents {
    has by_id: dict[str, Agent] = {};

    def resolve(aid: str) -> Agent | None {
        return self.by_id.get(aid);
    }
}

"""Deterministic fresh-graph builder from a {aid: parent|None} map."""
def load_agents(parents: dict[str, str | None]) -> Agents {
    reg = Agents(by_id={});
    for aid in parents.keys() {
        a = Agent(aid=aid);
        root ++> a;
        reg.by_id[aid] = a;
    }
    p: str | None;
    for aid in parents.keys() {
        p = parents[aid];
        if p is not None {
            pa = reg.by_id.get(p);
            # Dangling parent refs (corrupt state) end the chain at the
            # last known agent -- tolerated, matching the source's get().
            if pa is not None {
                pa +>:ParentOf:+> reg.by_id[aid];
            }
        }
    }
    return reg;
}

walker ParentWalk {
    """Single-lineage ancestor chase with the explicit cycle policy."""
    has chain: list[str] = [];
    has claimed: dict[str, bool] = {};
    has revisit: str = "";

    can step with Agent entry {
        if here.aid in self.claimed {
            self.revisit = here.aid;
            disengage;
        }
        if len(self.chain) >= MAX_CHAIN {
            disengage;
        }
        self.claimed[here.aid] = True;
        self.chain.append(here.aid);
        visit [here <-:ParentOf:<-] else { disengage; }
    }
}

"""Number of parent hops from ``aid`` to its chain end; 0 when unknown."""
def agent_depth(reg: Agents, aid: str) -> int {
    a = reg.resolve(aid);
    if a is None {
        return 0;
    }
    w = a spawn ParentWalk();
    return len(w.chain) - 1;
}

"""Lineage ids in walk order ``[aid, parent, ...]``; empty when unknown."""
def chain_of(reg: Agents, aid: str) -> list[str] {
    a = reg.resolve(aid);
    if a is None {
        return [];
    }
    w = a spawn ParentWalk();
    return w.chain;
}

"""Ids of the offending parent cycle, or None when acyclic."""
def cycle_in(reg: Agents, aid: str) -> list[str] | None {
    a = reg.resolve(aid);
    if a is None {
        return None;
    }
    w = a spawn ParentWalk();
    if w.revisit == "" {
        return None;
    }
    start = w.chain.index(w.revisit);
    return w.chain[start:];
}
