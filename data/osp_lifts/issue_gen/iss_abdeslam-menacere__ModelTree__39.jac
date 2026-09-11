"""abdeslam-menacere/ModelTree#39 — Shareable lineage trail subgraph."""

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
