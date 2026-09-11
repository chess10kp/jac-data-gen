"""Guard: abdeslam-menacere/ModelTree#39."""

node ModelRelease { has name: str; }
edge Derives {}

obj LineageBoard { has nodes: dict[str, ModelRelease] = {}; }

walker UpTrail {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with ModelRelease entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        for par in [here <-:Derives:<-][?:ModelRelease] {
            if not (par.name in self.claimed) { visit [par]; }
        }
    }
}

def load_lineage(
    nodes: list[str],
    derives: list[tuple[str, str]],
) -> LineageBoard {
    board = LineageBoard();
    for name in nodes {
        nd = ModelRelease(name=name);
        root ++> nd;
        board.nodes[name] = nd;
    }
    for (parent, child) in derives {
        p = board.nodes.get(parent, None);
        c = board.nodes.get(child, None);
        if p is not None and c is not None { p +>:Derives:+> c; }
    }
    return board;
}

def trail_nodes(board: LineageBoard, focal: str) -> list[str] {
    nd = board.nodes.get(focal, None);
    if nd is None { return []; }
    acc: dict[str, bool] = {focal: True};
    up = nd spawn UpTrail(claimed={}, found=[]);
    for n in up.found { acc[n] = True; }
    for ch in [nd ->:Derives:->][?:ModelRelease] {
        acc[ch.name] = True;
    }
    out: list[str] = [];
    for k in acc.keys() { out.append(k); }
    return sorted(out);
}

def sibling_nodes(board: LineageBoard, focal: str) -> list[str] {
    nd = board.nodes.get(focal, None);
    if nd is None { return []; }
    parents = [nd <-:Derives:<-][?:ModelRelease];
    if len(parents) == 0 { return []; }
    par = parents[0];
    sibs: list[str] = [];
    for ch in [par ->:Derives:->][?:ModelRelease] {
        if ch.name != focal { sibs.append(ch.name); }
    }
    return sorted(sibs);
}

test "trail around focal release" {
    b = load_lineage(
        ["root", "a", "b", "c", "d"],
        [("root", "a"), ("a", "b"), ("a", "c"), ("b", "d")],
    );
    assert trail_nodes(b, "a") == ["a", "b", "c", "root"];
    assert trail_nodes(b, "d") == ["a", "b", "d", "root"];
}

test "siblings exclude focal" {
    b = load_lineage(
        ["root", "a", "b", "c"],
        [("root", "a"), ("a", "b"), ("a", "c")],
    );
    assert sibling_nodes(b, "b") == ["c"];
    assert sibling_nodes(b, "root") == [];
}

test "uptrail cycle once only" {
    b = load_lineage(["a", "b"], [("a", "b")]);
    b.nodes["b"] +>:Derives:+> b.nodes["a"];
    w = b.nodes["a"] spawn UpTrail(claimed={}, found=[]);
    assert sorted(w.found) == ["a", "b"];
}

test "unknown focal empty" {
    b = load_lineage(["solo"], []);
    assert trail_nodes(b, "missing") == [];
}
