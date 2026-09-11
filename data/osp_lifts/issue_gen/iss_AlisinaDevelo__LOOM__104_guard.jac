"""Guard: AlisinaDevelo/LOOM#104."""

node EvidenceNode { has nid: str; }
edge ProvenanceOf {}

obj ProvenanceGraph { has nodes: dict[str, EvidenceNode] = {}; }

def load_provenance(
    nodes: list[str],
    derives: list[tuple[str, str]],
) -> ProvenanceGraph {
    g = ProvenanceGraph();
    for nid in nodes {
        nd = EvidenceNode(nid=nid);
        root ++> nd;
        g.nodes[nid] = nd;
    }
    for (child, parent) in derives {
        c = g.nodes.get(child, None);
        p = g.nodes.get(parent, None);
        if c is not None and p is not None { p +>:ProvenanceOf:+> c; }
    }
    return g;
}

def upstream_lineage(g: ProvenanceGraph, node_id: str, limit: int) -> list[str] {
    nd = g.nodes.get(node_id, None);
    if nd is None { return []; }
    acc: dict[str, bool] = {node_id: True};
    frontier = [nd <-:ProvenanceOf:<-][?:EvidenceNode];
    depth = 0;
    while len(frontier) > 0 and depth < limit {
        nxt_frontier: list[EvidenceNode] = [];
        for par in frontier {
            if not (par.nid in acc) {
                acc[par.nid] = True;
                for gp in [par <-:ProvenanceOf:<-][?:EvidenceNode] {
                    nxt_frontier.append(gp);
                }
            }
        }
        frontier = nxt_frontier;
        depth += 1;
    }
    out: list[str] = [];
    for k in acc.keys() { out.append(k); }
    return sorted(out);
}

def within_bound(g: ProvenanceGraph, node_id: str, limit: int) -> bool {
    trail = upstream_lineage(g, node_id, limit + 10);
    ups = 0;
    for n in trail {
        if n != node_id { ups += 1; }
    }
    return ups <= limit;
}

test "bounded upstream lineage" {
    g = load_provenance(
        ["capture", "snapshot", "source", "root"],
        [("capture", "snapshot"), ("snapshot", "source"), ("source", "root")],
    );
    assert upstream_lineage(g, "capture", 2) == ["capture", "snapshot", "source"];
    assert within_bound(g, "capture", 3) is True;
    assert within_bound(g, "capture", 2) is False;
}

test "depth zero only focal" {
    g = load_provenance(["a", "b"], [("a", "b")]);
    assert upstream_lineage(g, "a", 0) == ["a"];
}

test "unknown node empty" {
    g = load_provenance(["solo"], []);
    assert upstream_lineage(g, "ghost", 3) == [];
}
