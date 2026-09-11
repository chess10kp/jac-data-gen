"""AmpersandTarski/Ampersand#1651 — Kleene plus/star relation reachability."""

node RelNode { has name: str; }
edge RelEdge {}

obj RelationGraph {
    has nodes: dict[str, RelNode] = {};
}

walker PlusWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with RelNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:RelEdge:->][?:RelNode];
    }
}

def load_relation(
    nodes: list[str],
    pairs: list[tuple[str, str]],
) -> RelationGraph {
    g = RelationGraph();
    for n in nodes {
        if n not in g.nodes {
            nd = RelNode(name=n);
            root ++> nd;
            g.nodes[n] = nd;
        }
    }
    for (src, dst) in pairs {
        a = g.nodes.get(src, None);
        b = g.nodes.get(dst, None);
        if a is not None and b is not None { a +>:RelEdge:+> b; }
    }
    return g;
}

def kleene_plus(g: RelationGraph, start: str) -> list[str] {
    anchor = g.nodes.get(start, None);
    if anchor is None { return []; }
    claimed: dict[str, bool] = {start: True};
    snap: list[str] = [];
    for nxt in [anchor ->:RelEdge:->][?:RelNode] {
        if nxt.name not in claimed {
            claimed[nxt.name] = True;
            snap.append(nxt.name);
        }
    }
    i = 0;
    while i < len(snap) {
        nid = snap[i];
        i += 1;
        nd = g.nodes.get(nid, None);
        if nd is None { continue; }
        for nxt in [nd ->:RelEdge:->][?:RelNode] {
            if nxt.name not in claimed {
                claimed[nxt.name] = True;
                snap.append(nxt.name);
            }
        }
    }
    return sorted(snap);
}

def kleene_star(g: RelationGraph, start: str) -> list[str] {
    if start not in g.nodes { return []; }
    return sorted([start] + kleene_plus(g, start));
}

def has_path(g: RelationGraph, src: str, dst: str) -> bool {
    if src not in g.nodes or dst not in g.nodes { return False; }
    if src == dst { return True; }
    plus = kleene_plus(g, src);
    for n in plus {
        if n == dst { return True; }
    }
    return False;
}
