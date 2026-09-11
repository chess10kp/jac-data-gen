"""Guard: specd-sdd/SpecD#39."""

node Symbol { has name: str; }
edge Calls {}

obj CodeGraph { has symbols: dict[str, Symbol] = {}; }

def load_graph(
    symbols: list[str],
    call_edges: list[tuple[str, str]],
) -> CodeGraph {
    g = CodeGraph();
    for sym in symbols {
        nd = Symbol(name=sym);
        root ++> nd;
        g.symbols[sym] = nd;
    }
    for (src, dst) in call_edges {
        a = g.symbols.get(src, None);
        b = g.symbols.get(dst, None);
        if a is not None and b is not None { a +>:Calls:+> b; }
    }
    return g;
}

def reachable_flow(g: CodeGraph, entry_sym: str, max_depth: int) -> list[str] {
    nd = g.symbols.get(entry_sym, None);
    if nd is None { return []; }
    seen: dict[str, bool] = {entry_sym: True};
    depth_map: dict[str, int] = {entry_sym: 0};
    frontier: list[str] = [entry_sym];
    i = 0;
    while i < len(frontier) {
        cur_name = frontier[i];
        i += 1;
        cur_depth = depth_map[cur_name];
        if cur_depth >= max_depth { continue; }
        cur_nd = g.symbols.get(cur_name, None);
        if cur_nd is None { continue; }
        for nxt in [cur_nd ->:Calls:->][?:Symbol] {
            next_depth = cur_depth + 1;
            if not (nxt.name in seen) {
                seen[nxt.name] = True;
                depth_map[nxt.name] = next_depth;
                frontier.append(nxt.name);
            }
        }
    }
    out: list[str] = [];
    for k in seen.keys() { out.append(k); }
    return sorted(out);
}

def process_count(g: CodeGraph, entries: list[str], max_depth: int) -> int {
    merged: dict[str, bool] = {};
    for ent in entries {
        for sym in reachable_flow(g, ent, max_depth) {
            merged[sym] = True;
        }
    }
    return len(merged);
}

test "login flow reachability" {
    g = load_graph(
        ["login", "auth", "session", "email", "register"],
        [
            ("login", "auth"),
            ("auth", "session"),
            ("register", "auth"),
            ("register", "email"),
        ],
    );
    assert reachable_flow(g, "login", 3) == ["auth", "login", "session"];
    assert process_count(g, ["login", "register"], 2) == 5;
}

test "depth cap limits flow" {
    g = load_graph(
        ["a", "b", "c", "d"],
        [("a", "b"), ("b", "c"), ("c", "d")],
    );
    assert reachable_flow(g, "a", 1) == ["a", "b"];
}

test "diamond call graph once only" {
    g = load_graph(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "leaf"),
            ("right", "leaf"),
        ],
    );
    assert reachable_flow(g, "hub", 3) == ["hub", "leaf", "left", "right"];
}

test "unknown entry empty" {
    g = load_graph(["solo"], []);
    assert reachable_flow(g, "ghost", 2) == [];
}
