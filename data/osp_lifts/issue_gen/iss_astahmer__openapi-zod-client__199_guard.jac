"""Recursive OpenAPI schema export resolution.

astahmer/openapi-zod-client#199
"""

node Schema {
    has cid: str;
}

edge Ref {}

walker Collect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Schema entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        kids: list[Schema] = [here ->:Ref:->][?:Schema];
        visit :0: kids;
    }
}

walker ReachBack {
    has goal: str = "";
    has claimed: dict[str, bool] = {};
    has on_path: bool = False;

    can hunt with Schema entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.goal {
            self.on_path = True;
            print(here.cid);
            disengage;
        }
        kids: list[Schema] = [here ->:Ref:->][?:Schema];
        visit kids else {
            disengage;
        }
    }
}

def build_adjacency(schemas: dict[str, list[str]]) -> dict[str, list[str]] {
    out: dict[str, list[str]] = {};
    keys = sorted(schemas);
    for k in keys {
        refs: list[str] = schemas[k];
        row: list[str] = [];
        for r in refs {
            row.append(r);
        }
        out[k] = row;
    }
    return out;
}

def _wire_graph(adj: dict[str, list[str]], start: str) -> Schema | None {
    nodes: dict[str, Schema] = {};
    names = sorted(adj);
    for n in names {
        nd = Schema(cid=n);
        nodes[n] = nd;
        root ++> nd;
    }
    for n in names {
        src = nodes[n];
        refs: list[str] = adj[n];
        for r in refs {
            if r in nodes {
                dst = nodes[r];
                src +>:Ref:+> dst;
            }
        }
    }
    if start in nodes {
        return nodes[start];
    }
    return None;
}

def collect_refs(adj: dict[str, list[str]], start: str) -> list[str] {
    ent = _wire_graph(adj, start);
    if ent is None {
        return [];
    }
    w = ent spawn Collect(claimed={});
    return sorted(w.found);
}

def in_cycle(adj: dict[str, list[str]], name: str) -> bool {
    refs: list[str] = [];
    if name in adj {
        refs = adj[name];
    }
    if name in refs {
        return True;
    }
    ent = _wire_graph(adj, name);
    if ent is None {
        return False;
    }
    kids: list[Schema] = [ent ->:Ref:->][?:Schema];
    for ch in kids {
        rb = ch spawn ReachBack(goal=name, claimed={});
        if rb.on_path {
            return True;
        }
    }
    return False;
}

def missing_exports(
    adj: dict[str, list[str]],
    start: str,
    exported: list[str],
) -> list[str] {
    exp: dict[str, bool] = {};
    for e in exported {
        exp[e] = True;
    }
    reach = collect_refs(adj, start);
    need: list[str] = [];
    for n in reach {
        if n in exp {
            continue;
        }
        if in_cycle(adj, n) {
            need.append(n);
        }
    }
    return sorted(need);
}

with entry {
    demo: dict[str, list[str]] = {"Item": ["Item"]};
    adj = build_adjacency(demo);
    ent = _wire_graph(adj, "Item");
    if ent is not None {
        w = ent spawn Collect(claimed={});
        print(w.found);
    }
}

test "build_adjacency_sorted" {
    raw: dict[str, list[str]] = {"Z": ["A"], "A": []};
    adj = build_adjacency(raw);
    keys = sorted(adj);
    assert keys == ["A", "Z"];
    assert adj["Z"] == ["A"];
}

test "collect_refs_self_recursive" {
    schemas: dict[str, list[str]] = {"Item": ["Item"]};
    adj = build_adjacency(schemas);
    got = collect_refs(adj, "Item");
    assert got == ["Item"];
}

test "collect_refs_linear_chain" {
    schemas: dict[str, list[str]] = {
        "A": ["B"],
        "B": ["C"],
        "C": [],
    };
    adj = build_adjacency(schemas);
    got = collect_refs(adj, "A");
    assert got == ["A", "B", "C"];
}

test "in_cycle_self_ref" {
    schemas: dict[str, list[str]] = {"Item": ["Item"]};
    adj = build_adjacency(schemas);
    assert in_cycle(adj, "Item") is True;
}

test "in_cycle_dag_leaf" {
    schemas: dict[str, list[str]] = {"A": ["B"], "B": []};
    adj = build_adjacency(schemas);
    assert in_cycle(adj, "B") is False;
}

test "missing_exports_recursive_unexported" {
    schemas: dict[str, list[str]] = {"Item": ["Item"]};
    adj = build_adjacency(schemas);
    need = missing_exports(adj, "Item", []);
    assert need == ["Item"];
    need2 = missing_exports(adj, "Item", ["Item"]);
    assert need2 == [];
}
