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


test "linear lineage depth and chain" {
    reg = load_agents({"a1": None, "a2": "a1", "a3": "a2"});
    assert chain_of(reg, "a3") == ["a3", "a2", "a1"];
    assert chain_of(reg, "a1") == ["a1"];
    assert agent_depth(reg, "a3") == 2;
    assert agent_depth(reg, "a1") == 0;
    assert cycle_in(reg, "a3") == None;
}

test "unknown id and dangling parent" {
    reg = load_agents({"a1": "missing", "a2": "a1"});
    other = load_agents({"a1": None});
    assert agent_depth(other, "ghost") == 0;
    assert chain_of(other, "ghost") == [];
    assert chain_of(reg, "a2") == ["a2", "a1"];
    assert agent_depth(reg, "a2") == 1;
    assert cycle_in(reg, "a2") == None;
}

test "mutual cycle breaks instead of wedging" {
    mutual = load_agents({"A": "B", "B": "A"});
    assert agent_depth(mutual, "A") == 1;
    assert chain_of(mutual, "A") == ["A", "B"];
    assert cycle_in(mutual, "A") == ["A", "B"];
    assert cycle_in(mutual, "B") == ["B", "A"];
}

test "self parent and three-node cycle" {
    selfp = load_agents({"S": "S"});
    assert chain_of(selfp, "S") == ["S"];
    assert cycle_in(selfp, "S") == ["S"];
    tri = load_agents({"A": "B", "B": "C", "C": "A", "pre": "A"});
    assert cycle_in(tri, "pre") == ["A", "B", "C"];
    assert chain_of(tri, "pre") == ["pre", "A", "B", "C"];
}

test "cap truncates runaway chains" {
    spec: dict[str, str | None] = {"n0": None};
    for i in range(1, MAX_CHAIN + 10) {
        spec["n" + str(i)] = "n" + str(i - 1);
    }
    deep = load_agents(spec);
    assert agent_depth(deep, "n" + str(MAX_CHAIN + 9)) == MAX_CHAIN - 1;
    assert cycle_in(deep, "n" + str(MAX_CHAIN + 9)) == None;
}
