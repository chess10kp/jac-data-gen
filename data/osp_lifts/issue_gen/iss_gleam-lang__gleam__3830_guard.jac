# gleam-lang/gleam#3830 — mutual recursion TCO group discovery
# Models finding strongly connected components (mutual recursion groups)
# among functions via a hand-rolled call graph, then emitting a trampoline
# dispatcher per group.

node Func {
    has name: str;
    has is_tail: bool = False;
}

edge Calls {}

obj Graph {
    has root: Func;
    has by_name: dict[str, Func];

    def get(name: str) -> Func | None {
        if name in self.by_name {
            return self.by_name[name];
        }
        return None;
    }

    def call(name: str, target: str) -> None {
        src = self.get(name);
        dst = self.get(target);
        if src is not None and dst is not None {
            src +>:Calls:+> dst;
        }
    }

    def members() -> list[str] {
        names: list[str] = [];
        for f in [self.root ->:Calls:->][?:Func] {
            names.append(f.name);
        }
        return sorted(names);
    }
}

# Tarjan-free mutual-group finder: BFS from each node over the call graph,
# keep a group when a cycle reaches back to the seed (mutual recursion).
def mutual_groups(g: Graph) -> list[list[str]] {
    groups: list[list[str]] = [];
    seen_seeds: dict[str, bool] = {};
    for seed in [g.root ->:Calls:->][?:Func] {
        if seed.name in seen_seeds {
            continue;
        }
        seen_seeds[seed.name] = True;
        group: dict[str, bool] = {};
        group[seed.name] = True;
        frontier: list[Func] = [seed];
        found_back: bool = False;
        steps: int = 0;
        while len(frontier) > 0 and steps < 200 {
            cur = frontier.pop();
            steps = steps + 1;
            for nxt in [cur ->:Calls:->][?:Func] {
                if nxt.name == seed.name {
                    found_back = True;
                }
                if nxt.name not in group {
                    group[nxt.name] = True;
                    frontier.append(nxt);
                }
            }
        }
        if found_back {
            members: list[str] = [];
            for m in group {
                members.append(m);
            }
            groups.append(sorted(members));
        }
    }
    return groups;
}

# Walk one mutual group (a cyclic component) with claim-map + skip cycle policy.
walker GroupWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Func entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        kids: list[Func] = [here ->:Calls:->][?:Func];
        visit kids;
    }
}

def build(names: list[str], edges: list[tuple[str, str]]) -> Graph {
    g_root = Func(name="__root__");
    nodes: dict[str, Func] = {};
    for n in names {
        f = Func(name=n);
        nodes[n] = f;
        g_root +>:Calls:+> f;
    }
    g = Graph(root=g_root, by_name=nodes);
    for e in edges {
        g.call(e[0], e[1]);
    }
    return g;
}

def tco_dispatch(g: Graph, entry: str) -> list[str] {
    # returns the mutually recursive closure reachable from entry (claim-map walk)
    seed = g.get(entry);
    if seed is None {
        return [];
    }
    wk = seed spawn GroupWalk(claimed={}, found=[]);
    return sorted(wk.found);
}

test "mutual_pair_up_down" {
    g = build(["up", "down", "helper"], [("up", "down"), ("down", "up")]);
    assert tco_dispatch(g, "up") == ["down", "up"];
    assert tco_dispatch(g, "helper") == ["helper"];
}

test "diamond_revisit_adversarial" {
    # edges inserted so a revisit fires before deeper first-visits
    g = build(["a", "b", "c", "d"], [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d"), ("d", "a")]);
    assert tco_dispatch(g, "a") == ["a", "b", "c", "d"];
}

test "unknown_id_tolerance" {
    g = build(["x"], []);
    assert tco_dispatch(g, "nope") == [];
    assert g.get("nope") is None;
}

test "self_recursion_single" {
    g = build(["loop"], [("loop", "loop")]);
    assert tco_dispatch(g, "loop") == ["loop"];
    assert len(mutual_groups(g)) == 1;
}

test "groups_split_independent_cycles" {
    g = build(["u", "d", "p", "q"], [("u", "d"), ("d", "u"), ("p", "q"), ("q", "p")]);
    assert mutual_groups(g) == [["d", "u"], ["p", "q"]];
}
