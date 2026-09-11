"""Guard tests for iss_mtetno__devtools__6.jac"""

obj MetricTree { has nodes: dict[str, MetricNode] = {}; }
node MetricNode { has nid: str; has value: int; }
edge ChildOf {}

walker DescendantWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_nid: str = "";

    can step with MetricNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.nid != self.start_nid { self.reached.append(here.nid); }
        for ch in [here <-:ChildOf:<-] { visit [ch]; }
    }
}

def load_tree(
    nodes: list[tuple[str, int]],
    parent_edges: list[tuple[str, str]],
) -> MetricTree {
    g = MetricTree();
    for (nid, val) in nodes {
        n = MetricNode(nid=nid, value=val);
        root ++> n;
        g.nodes[nid] = n;
    }
    for (child, par) in parent_edges {
        c = g.nodes.get(child, None);
        p = g.nodes.get(par, None);
        if c is not None and p is not None { c +>:ChildOf:+> p; }
    }
    return g;
}

def descendant_ids(g: MetricTree, node_id: str) -> list[str] {
    anchor = g.nodes.get(node_id, None);
    if anchor is None { return []; }
    w = anchor spawn DescendantWalk(claimed={}, reached=[], start_nid=node_id);
    return sorted(w.reached);
}

def recursive_sum(g: MetricTree, node_id: str) -> int {
    anchor = g.nodes.get(node_id, None);
    if anchor is None { return 0; }
    w = anchor spawn DescendantWalk(claimed={}, reached=[], start_nid=node_id);
    total = anchor.value;
    for nid in w.reached {
        n = g.nodes.get(nid, None);
        if n is not None { total += n.value; }
    }
    return total;
}

test "chain descendants and recursive sum" {
    g = load_tree(
        [("root", 10), ("a", 20), ("b", 30), ("c", 40)],
        [("a", "root"), ("b", "a"), ("c", "b")],
    );
    assert descendant_ids(g, "root") == ["a", "b", "c"];
    assert recursive_sum(g, "root") == 100;
    assert recursive_sum(g, "b") == 70;
}

test "unknown node tolerance" {
    g = load_tree([("only", 5)], []);
    assert descendant_ids(g, "missing") == [];
    assert recursive_sum(g, "missing") == 0;
}

test "parent cycle terminates" {
    g = load_tree(
        [("a", 1), ("b", 2), ("c", 3)],
        [("b", "a"), ("c", "b"), ("a", "c")],
    );
    assert descendant_ids(g, "b") == ["a", "c"];
    assert recursive_sum(g, "b") == 6;
}

test "adversarial breadth sibling closure" {
    g = load_tree(
        [
            ("root", 1),
            ("w1", 2),
            ("w2", 3),
            ("w3", 4),
            ("deep", 50),
        ],
        [
            ("w1", "root"),
            ("w2", "root"),
            ("w3", "root"),
            ("deep", "w1"),
        ],
    );
    assert descendant_ids(g, "root") == ["deep", "w1", "w2", "w3"];
    assert recursive_sum(g, "root") == 60;
}
