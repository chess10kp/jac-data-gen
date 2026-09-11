"""OSP lift: blast-radius reverse traversal. Source: MrNedimBoztepe/Shonkor#101."""

node Service {
    has name: str;
}

edge Consumes {}

walker BlastWalker {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has seed: str = "";

    can begin with Root entry {
        for s in [-->][?:Service] {
            if s.name == self.seed {
                visit [s];
            }
        }
    }

    can step with Service entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [<--];
    }

    can finish with Root exit {
        report self.reached;
    }
}

def _wire(edges: list[tuple[str, str]]) -> dict[str, Service] {
    nodes: dict[str, Service] = {};
    for (consumer, producer) in edges {
        if consumer not in nodes {
            nodes[consumer] = Service(name=consumer);
            root ++> nodes[consumer];
        }
        if producer not in nodes {
            nodes[producer] = Service(name=producer);
            root ++> nodes[producer];
        }
        nodes[consumer] +>:Consumes:+> nodes[producer];
    }
    return nodes;
}

def blast_radius(changed: str, edges: list[tuple[str, str]]) -> list[str] {
    nodes = _wire(edges);
    if changed not in nodes {
        return [];
    }
    w = root spawn BlastWalker(seed=changed, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def provenance_chain(node: str, parent_of: dict[str, str]) -> list[str] {
    chain: list[str] = [];
    cur: str | None = node;
    seen: dict[str, bool] = {};
    while cur is not None and cur not in seen {
        seen[cur] = True;
        chain.append(cur);
        cur = parent_of.get(cur);
    }
    return chain;
}

test "diamond blast radius adversarial" {
    edges = [("x", "p"), ("y", "p"), ("z", "x"), ("z", "y")];
    got = blast_radius("p", edges);
    assert got == ["p", "x", "y", "z"];
}

test "cycle blast once per service" {
    edges = [("a", "b"), ("b", "c"), ("c", "a")];
    got = blast_radius("b", edges);
    assert sorted(got) == ["a", "b", "c"];
    assert len(got) == 3;
}

test "provenance stops on cycle" {
    parents = {"a": "b", "b": "c", "c": "a"};
    got = provenance_chain("a", parents);
    assert got == ["a", "b", "c"];
}
