"""Gradle CI cold-resolve planner. Source: Monkopedia/sdbus-kotlin#253."""

node Artifact {
    has name: str;
}

edge Depends {}

walker ResolveWalker {
    has start: str = "";
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has misses: list[str] = [];
    has cache: dict[str, str] = {};

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
        if here.name in self.cache {
            self.hits.append(here.name);
        } else {
            self.misses.append(here.name);
        }
        visit [-->];
    }
}

def _wire(deps: dict[str, list[str]]) {
    nodes: dict[str, Artifact] = {};
    for (src, tgts) in deps.items() {
        if src not in nodes {
            nodes[src] = Artifact(name=src);
            root ++> nodes[src];
        }
        for t in tgts {
            if t not in nodes {
                nodes[t] = Artifact(name=t);
                root ++> nodes[t];
            }
            nodes[src] +>:Depends:+> nodes[t];
        }
    }
}

def resolve_with_cache(
    artifact: str,
    deps: dict[str, list[str]],
    cache: dict[str, str],
) -> tuple[list[str], list[str]] {
    _wire(deps);
    w = root spawn ResolveWalker(start=artifact, cache=cache);
    return (sorted(w.hits), sorted(w.misses));
}

def ancestor_chain(job: str, parent: dict[str, str]) -> list[str] {
    chain: list[str] = [];
    cur = job;
    while cur in parent {
        cur = parent[cur];
        chain.append(cur);
    }
    return chain;
}

def uncached_misses(artifacts: list[str], cache: set[str]) -> list[str] {
    out: list[str] = [];
    for art in artifacts {
        if art not in cache {
            out.append(art);
        }
    }
    seen: dict[str, bool] = {};
    deduped: list[str] = [];
    for a in out {
        if a not in seen {
            seen[a] = True;
            deduped.append(a);
        }
    }
    return sorted(deduped);
}
