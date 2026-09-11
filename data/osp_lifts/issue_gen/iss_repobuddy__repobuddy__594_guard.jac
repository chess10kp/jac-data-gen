"""Reusable-workflow blast radius, lifted to OSP.

Workflow refs become Wf nodes; each Uses entry of the source's workflows
dict becomes a pair of typed edges -- Uses (caller -> callee, the domain
direction of ``uses:``) and CalledBy (callee -> caller, the blast-radius
direction) -- so the deque BFS over the adjacency dict becomes walkers:
``callers_of`` is a shortest-chain relaxation walk over CalledBy edges
whose hop budget is the caller bound, and ``affected_repos`` a claim-once
flood over the same edges that the façade maps to repository names. The
claim maps ARE the cycle policy: cyclic usage graphs terminate without
losing callers.
Ref: repobuddy/repobuddy#594
"""
node Wf {
    has ref: str;
}
edge Uses {}       # caller -> callee (the workflow's ``uses:`` step)
edge CalledBy {}   # callee -> caller (blast-radius direction)

glob MAX_CALLER_HOPS: int = 3;

"""Loader handle: ref-string parameters resolve through this lookup map."""
obj CallGraph {
    has nodes: dict[str, Wf];

    def resolve(ref: str) -> Wf | None {
        return self.nodes.get(ref);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def load_graph(graph: dict) -> CallGraph {
    cg = CallGraph(nodes={});
    repos: dict = graph["repos"];
    for ref in list(repos.keys()) {
        w = Wf(ref=str(ref));
        root ++> w;
        cg.nodes[str(ref)] = w;
    }
    wfs: dict = graph["workflows"];
    for callee in list(wfs.keys()) {
        target = cg.resolve(str(callee));
        if target is None {
            continue;  # refs outside the repos map do not exist
        }
        for caller in list(wfs[callee]) {
            c = cg.resolve(str(caller));
            if c is None {
                continue;
            }
            c +>:Uses:+> target;
            target +>:CalledBy:+> c;
        }
    }
    return cg;
}

walker CallerHops {
    # Cycle policy: claim map keyed by ref (jac walkers do not dedupe).
    # A non-improving revisit skips; a strictly shallower arrival
    # re-expands, so the map ends holding each caller's shortest hop
    # distance -- the depth-bounded caller walk.
    has best: dict[str, int] = {};
    has hops: int = 0;
    has budget: int = 3;

    can step with Wf entry {
        if here.ref in self.best and self.hops >= self.best[here.ref] {
            skip;
        }
        self.best[here.ref] = self.hops;
        if self.hops < self.budget {
            for caller in [here->:CalledBy:->] {
                caller spawn CallerHops(best=self.best, hops=self.hops + 1, budget=self.budget);
            }
        }
    }
}

walker CallerFlood {
    # Cycle policy: claim-once map; revisits skip, so cyclic usage graphs
    # terminate while every caller is collected exactly once.
    has claimed: dict[str, bool] = {};
    has members: list[str] = [];

    can step with Wf entry {
        if here.ref in self.claimed {
            skip;
        }
        self.claimed[here.ref] = True;
        self.members.append(here.ref);
        visit [->:CalledBy:->] else { disengage; }
    }
}

"""Caller refs within ``max_hops`` Uses hops of ``ref``, sorted."""
def callers_of(graph: dict, ref: str, max_hops: int = MAX_CALLER_HOPS) -> list[str] {
    cg = load_graph(graph);
    start = cg.resolve(ref);
    if start is None {
        raise KeyError(ref);
    }
    w = start spawn CallerHops(best={}, hops=0, budget=max_hops);
    out: list[str] = [];
    for k in w.best.keys() {
        if k != ref and w.best[k] <= max_hops {
            out.append(k);
        }
    }
    return sorted(out);
}

"""Repository names of the full transitive caller closure, sorted."""
def affected_repos(graph: dict, ref: str) -> list[str] {
    cg = load_graph(graph);
    start = cg.resolve(ref);
    if start is None {
        raise KeyError(ref);
    }
    w = start spawn CallerFlood(claimed={});
    repos: dict = graph["repos"];
    names: set[str] = set();
    for m in w.members {
        if m != ref and m in repos {
            names.add(str(repos[m]));
        }
    }
    return sorted(names);
}


test "bounded caller walk over the incident graph" {
    G = {
        "workflows": {
            "hub/pnpm-release.yml": ["app1/ci.yml", "app2/ci.yml"],
            "app2/ci.yml": ["app3/build.yml"],
        },
        "repos": {
            "hub/pnpm-release.yml": "hub",
            "app1/ci.yml": "app1",
            "app2/ci.yml": "app2",
            "app3/build.yml": "app3",
        },
    };
    assert callers_of(G, "hub/pnpm-release.yml", max_hops=1) == ["app1/ci.yml", "app2/ci.yml"];
    assert callers_of(G, "hub/pnpm-release.yml", max_hops=2) == ["app1/ci.yml", "app2/ci.yml", "app3/build.yml"];
    assert callers_of(G, "hub/pnpm-release.yml") == ["app1/ci.yml", "app2/ci.yml", "app3/build.yml"];
    assert callers_of(G, "app2/ci.yml", max_hops=1) == ["app3/build.yml"];
    assert callers_of(G, "app3/build.yml") == [];
    assert callers_of(G, "hub/pnpm-release.yml", max_hops=0) == [];
}

test "blast radius maps closure to deduped repo names" {
    G2 = {
        "workflows": {
            "hub/pnpm-release.yml": ["app1/ci.yml", "app1/nightly.yml", "app2/ci.yml"],
            "app2/ci.yml": ["app3/build.yml"],
        },
        "repos": {
            "hub/pnpm-release.yml": "hub",
            "app1/ci.yml": "app1",
            "app1/nightly.yml": "app1",
            "app2/ci.yml": "app2",
            "app3/build.yml": "app3",
        },
    };
    assert affected_repos(G2, "hub/pnpm-release.yml") == ["app1", "app2", "app3"];
    assert affected_repos(G2, "app3/build.yml") == [];
    G = {
        "workflows": {
            "hub/pnpm-release.yml": ["app1/ci.yml", "app2/ci.yml"],
            "app2/ci.yml": ["app3/build.yml"],
        },
        "repos": {
            "hub/pnpm-release.yml": "hub",
            "app1/ci.yml": "app1",
            "app2/ci.yml": "app2",
            "app3/build.yml": "app3",
        },
    };
    assert affected_repos(G, "app2/ci.yml") == ["app3"];
}

test "adversarial-order diamond counts the short chain" {
    D = {
        "workflows": {
            "hub/r.yml": ["a/w.yml", "b/w.yml"],
            "a/w.yml": ["m/w.yml"],
            "m/w.yml": ["top/w.yml"],
            "b/w.yml": ["top/w.yml"],
        },
        "repos": {
            "hub/r.yml": "hub",
            "a/w.yml": "a",
            "b/w.yml": "b",
            "m/w.yml": "m",
            "top/w.yml": "top",
        },
    };
    assert callers_of(D, "hub/r.yml", max_hops=2) == ["a/w.yml", "b/w.yml", "m/w.yml", "top/w.yml"];
    assert callers_of(D, "hub/r.yml") == ["a/w.yml", "b/w.yml", "m/w.yml", "top/w.yml"];
}

test "cyclic usage graphs terminate" {
    C = {
        "workflows": {
            "w1.yml": ["w2.yml"],
            "w2.yml": ["w1.yml", "leaf.yml"],
        },
        "repos": {"w1.yml": "r1", "w2.yml": "r2", "leaf.yml": "r3"},
    };
    assert callers_of(C, "w1.yml") == ["leaf.yml", "w2.yml"];
    assert affected_repos(C, "w1.yml") == ["r2", "r3"];
}

test "refs outside the repos map do not exist" {
    U = {
        "workflows": {
            "hub/r.yml": ["ghost/w.yml", "app/ci.yml"],
            "ghost/w.yml": ["app/nightly.yml"],
        },
        "repos": {"hub/r.yml": "hub", "app/ci.yml": "app", "app/nightly.yml": "app"},
    };
    assert callers_of(U, "hub/r.yml") == ["app/ci.yml"];
    assert affected_repos(U, "hub/r.yml") == ["app"];
}

test "unknown starting ref raises KeyError" {
    G = {
        "workflows": {"hub/pnpm-release.yml": ["app1/ci.yml"]},
        "repos": {"hub/pnpm-release.yml": "hub", "app1/ci.yml": "app1"},
    };
    try {
        callers_of(G, "ghost.yml");
        assert False, "expected KeyError";
    } except KeyError { assert True; }
    try {
        affected_repos(G, "ghost.yml");
        assert False, "expected KeyError";
    } except KeyError { assert True; }
}
