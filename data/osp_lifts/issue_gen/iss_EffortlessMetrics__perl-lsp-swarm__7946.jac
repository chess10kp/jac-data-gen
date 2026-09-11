"""OSP lift: compiler cache + reverse invalidation. Source: EffortlessMetrics/perl-lsp-swarm#7946."""

node Artifact {
    has name: str;
}

edge Depends {}
edge RevDepends {}

walker FwdWalker {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for a in [-->][?:Artifact] {
            if a.name == self.start {
                visit [a];
            }
        }
    }

    can step with Artifact entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Depends:->];
    }

    can finish with Root exit {
        report self.reached;
    }
}

walker RevWalker {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start: str = "";

    can begin with Root entry {
        for a in [-->][?:Artifact] {
            if a.name == self.start {
                visit [a];
            }
        }
    }

    can step with Artifact entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:RevDepends:->];
    }

    can finish with Root exit {
        report self.reached;
    }
}

def _wire(edges: list[tuple[str, str]]) -> dict[str, Artifact] {
    nodes: dict[str, Artifact] = {};
    for (src, dst) in edges {
        if src not in nodes {
            nodes[src] = Artifact(name=src);
            root ++> nodes[src];
        }
        if dst not in nodes {
            nodes[dst] = Artifact(name=dst);
            root ++> nodes[dst];
        }
        nodes[src] +>:Depends:+> nodes[dst];
        nodes[dst] +>:RevDepends:+> nodes[src];
    }
    return nodes;
}

def artifact_closure(artifact: str, edges: list[tuple[str, str]]) -> list[str] {
    nodes = _wire(edges);
    if artifact not in nodes {
        return [];
    }
    w = root spawn FwdWalker(start=artifact, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def dependent_closure(artifact: str, edges: list[tuple[str, str]]) -> list[str] {
    nodes = _wire(edges);
    if artifact not in nodes {
        return [];
    }
    w = root spawn RevWalker(start=artifact, claimed={}, reached=[]);
    return sorted(w.reports[0] if w.reports else []);
}

def cache_lookup(key: str, cache: dict[str, str]) -> str | None {
    return cache.get(key);
}

def invalidate_artifact(
    artifact: str,
    edges: list[tuple[str, str]],
    cache: dict[str, str],
) -> list[str] {
    victims = dependent_closure(artifact, edges);
    for key in victims {
        if key in cache {
            del cache[key];
        }
    }
    return victims;
}
