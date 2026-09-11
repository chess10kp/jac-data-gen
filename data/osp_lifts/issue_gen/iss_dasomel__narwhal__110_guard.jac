"""Guard: dasomel/narwhal#110."""

node Service { has name: str; }
edge DependsOn {}

walker BlastWalker {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has seed: str = "";

    can begin with Root entry {
        for s in [-->][?:Service] { if s.name == self.seed { visit [s]; } }
    }
    can step with Service entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [<--];
    }
}

def _wire(edges: list[tuple[str, str]]) -> dict[str, Service] {
    nodes: dict[str, Service] = {};
    for (consumer, upstream) in edges {
        if consumer not in nodes { root ++> (nodes[consumer] := Service(name=consumer)); }
        if upstream not in nodes { root ++> (nodes[upstream] := Service(name=upstream)); }
        nodes[consumer] +>:DependsOn:+> nodes[upstream];
    }
    return nodes;
}

def blast_radius(changed: str, edges: list[tuple[str, str]]) -> list[str] {
    nodes = _wire(edges);
    if changed not in nodes { return []; }
    w = root spawn BlastWalker(seed=changed, claimed={}, reached=[]);
    return sorted(w.reached);
}

def upstream_chain(service: str, depends_on: dict[str, str]) -> list[str] {
    chain: list[str] = [];
    cur: str | None = service;
    seen: dict[str, bool] = {};
    while cur is not None and cur not in seen {
        seen[cur] = True;
        chain.append(cur);
        cur = depends_on.get(cur);
    }
    return chain;
}

test "diamond blast adversarial" {
    edges = [("x", "p"), ("y", "p"), ("z", "x"), ("z", "y")];
    assert blast_radius("p", edges) == ["p", "x", "y", "z"];
}

test "cycle once per service" {
    edges = [("a", "b"), ("b", "c"), ("c", "a")];
    got = blast_radius("b", edges);
    assert sorted(got) == ["a", "b", "c"] and len(got) == 3;
}

test "upstream stops on cycle" {
    deps = {"a": "b", "b": "c", "c": "a"};
    assert upstream_chain("a", deps) == ["a", "b", "c"];
}
