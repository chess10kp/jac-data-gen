"""OSP lift for gmeligio/gx#124 — composite action reference scan."""

node Action {
    has name: str;
    has is_composite: bool = False;
}

edge Uses {}

walker ScanWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with Action entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        visit [->:Uses:->][?:Action];
        if here.is_composite {
            for nxt in [here ->:Uses:->][?:Action] {
                if nxt.name not in self.claimed { visit [nxt]; }
            }
        }
    }
}

def _build_nodes(
    uses: list[tuple[str, str]], composite: set[str]
) -> dict[str, Action] {
    nodes: dict[str, Action] = {};
    for (src, dst) in uses {
        if src not in nodes {
            nodes[src] = Action(name=src, is_composite=src in composite);
        }
        if dst not in nodes {
            nodes[dst] = Action(name=dst, is_composite=dst in composite);
        }
        nodes[src] +>:Uses:+> nodes[dst];
    }
    return nodes;
}

def follow_local_uses(
    start: str,
    uses: list[tuple[str, str]],
    composite: set[str],
) -> list[str] {
    nodes = _build_nodes(uses, composite);
    nd = nodes.get(start, None);
    if nd is None { return []; }
    w = nd spawn ScanWalker();
    return w.order;
}

def nested_references(
    action: str,
    uses: list[tuple[str, str]],
    composite: set[str],
) -> list[str] {
    nodes = _build_nodes(uses, composite);
    nd = nodes.get(action, None);
    if nd is None or not nd.is_composite { return []; }
    out: list[str] = [];
    for nxt in [nd ->:Uses:->][?:Action] { out.append(nxt.name); }
    return sorted(out);
}

def managed_closure(
    seeds: list[str],
    uses: list[tuple[str, str]],
    composite: set[str],
) -> list[str] {
    seen: dict[str, bool] = {};
    for seed in sorted(seeds) {
        for nm in follow_local_uses(seed, uses, composite) { seen[nm] = True; }
    }
    return sorted(seen.keys());
}

test "diamond composite revisit once" {
    uses = [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d"), ("d", "e")];
    comp = {"d"};
    got = follow_local_uses("a", uses, comp);
    assert got[0] == "a";
    assert got[-1] == "e";
    assert len(got) == len(set(got));
}

test "nested refs only for composite" {
    uses = [("comp", "inner"), ("leaf", "x")];
    assert nested_references("comp", uses, {"comp"}) == ["inner"];
    assert nested_references("leaf", uses, {"comp"}) == [];
}

test "managed closure merges seeds" {
    uses = [("s1", "m"), ("s2", "m")];
    assert managed_closure(["s1", "s2"], uses, set()) == ["m", "s1", "s2"];
}
