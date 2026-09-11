"""OSP lift for EffortlessMetrics/ripr-swarm#1658 — bounded evidence summaries."""

node Evidence {
    has name: str;
}

edge Relevant {}

walker EvidenceWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has start: str = "";
    has limit: int = 0;

    can begin with Root entry {
        for e in [-->][?:Evidence] {
            if e.name == self.start {
                visit [e];
            }
        }
    }

    can step with Evidence entry {
        if here.name in self.claimed {
            skip;
        }
        if len(self.order) >= self.limit {
            disengage;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        visit [-->];
    }

    can finish with Root exit {
        report self.order;
    }
}

def _wire(edges: list[tuple[str, str]]) -> None {
    nodes: dict[str, Evidence] = {};
    for (a, b) in edges {
        if a not in nodes {
            nodes[a] = Evidence(name=a);
            root ++> nodes[a];
        }
        if b not in nodes {
            nodes[b] = Evidence(name=b);
            root ++> nodes[b];
        }
        nodes[a] +>:Relevant:+> nodes[b];
    }
}

def evidence_reachable(
    seed: str,
    edges: list[tuple[str, str]],
    limit: int,
) -> list[str] {
    _wire(edges);
    w = root spawn EvidenceWalker(start=seed, limit=limit);
    return w.reports[0] if w.reports else [];
}

def summarize_assertions(findings: list[str], limit: int) -> list[str] {
    return sorted(findings)[:limit];
}

def transitive_evidence(
    crate: str,
    depends: list[tuple[str, str]],
) -> list[str] {
    _wire(depends);
    w = root spawn EvidenceWalker(start=crate, limit=1000);
    return sorted(w.reports[0] if w.reports else []);
}

test "diamond evidence once per node" {
    edges = [("r", "a"), ("r", "b"), ("a", "c"), ("b", "c")];
    got = evidence_reachable("r", edges, 10);
    assert got.count("c") == 1;
    assert len(got) == 4;
}

test "bounded summary" {
    assert summarize_assertions(["b", "a", "c"], 2) == ["a", "b"];
}

test "transitive deps sorted" {
    deps = [("app", "lib"), ("lib", "core")];
    assert transitive_evidence("app", deps) == ["app", "core", "lib"];
}
