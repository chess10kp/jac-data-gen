"""Ontology subgraph builder lifted to OSP (CatholicOS/ontokit-web#81).

The concept and edge tables die: ``subClassOf`` facts become a pair of
typed edges -- ``SubOut`` (specific --> general) and its inverse
``SubIn`` -- and lateral ``seeAlso`` links become ``SeeAlso`` /
``SeeAlsoInv``, so every BFS hop is a forward typed-edge hop instead of a
full-table rescan. The observable API semantics all survive: per-direction
depth limits, the node budget with an explicit truncation flag, optional
lateral expansion, and unknown IRIs failing closed.
"""

node Concept {
    has iri: str;
    has label: str;
}

edge SubOut: Concept --> Concept {}

edge SubIn: Concept --> Concept {}

edge SeeAlso: Concept --> Concept {}

edge SeeAlsoInv: Concept --> Concept {}

glob concepts: dict[str, Concept] = {};

glob subg_nodes: set[str] = set();

glob subg_truncated: bool = False;

glob node_budget: int = 200;


def add_concept(iri: str, label: str = "") -> None {
    if iri in concepts {
        raise ValueError("duplicate concept");
    }
    root ++> (c := Concept(iri=iri, label=label));
    concepts[iri] = c;
}


def add_edge(src: str, dst: str, etype: str = "subClassOf") -> None {
    # subClassOf: src is the more specific concept; seeAlso: lateral link
    for i in (src, dst) {
        if i not in concepts {
            raise KeyError(i);
        }
    }
    if etype == "subClassOf" {
        concepts[src] +>:SubOut:+> concepts[dst];
        concepts[dst] +>:SubIn:+> concepts[src];
    } elif etype == "seeAlso" {
        concepts[src] +>:SeeAlso:+> concepts[dst];
        concepts[dst] +>:SeeAlsoInv:+> concepts[src];
    } else {
        raise ValueError(etype);
    }
}


walker BudgetWalk {
    """Claims nodes along one hop type until depth or budget runs out.

    ``force`` lets an already-claimed seed still expand its neighbours
    (used by the lateral pass over the whole claimed neighbourhood).
    """
    has depth_left: int = 0;
    has go_up: bool = False;
    has lateral: bool = False;
    has force: bool = False;

    can go with Concept entry {
        if here.iri in subg_nodes {
            if not self.force {
                return;  # revisit: skip silently
            }
        } else {
            if len(subg_nodes) >= node_budget {
                subg_truncated = True;
                return;
            }
            subg_nodes.add(here.iri);
        }
        if self.depth_left == 0 {
            return;
        }
        nbrs: list[Concept] = [];
        if self.go_up {
            nbrs.extend([here ->:SubOut:->]);
        } elif self.lateral {
            nbrs.extend([here ->:SeeAlso:->]);
            nbrs.extend([here ->:SeeAlsoInv:->]);
        } else {
            nbrs.extend([here ->:SubIn:->]);
        }
        for nb in nbrs {
            sub = BudgetWalk(depth_left=self.depth_left - 1,
                             go_up=self.go_up, lateral=self.lateral);
            nb spawn sub;
        }
    }
}


def build_subgraph(focus: str, ancestors_depth: int = 2,
                   descendants_depth: int = 2, max_nodes: int = 200,
                   include_see_also: bool = True) -> dict {
    # bounded neighbourhood of focus with explicit truncation flag
    if focus not in concepts {
        raise KeyError(focus);
    }
    subg_nodes.clear();
    subg_truncated = False;
    node_budget = max_nodes;  # the walker claims focus itself

    w_up = concepts[focus] spawn BudgetWalk(depth_left=ancestors_depth,
                                           go_up=True);
    w_down = concepts[focus] spawn BudgetWalk(depth_left=descendants_depth);
    if include_see_also {
        for iri2 in sorted(list(subg_nodes)) {
            w_lat = concepts[iri2] spawn BudgetWalk(depth_left=1,
                                                   lateral=True,
                                                   force=True);
        }
    }

    edge_set: set[tuple] = set();
    for iri in sorted(subg_nodes) {
        for t in [concepts[iri] ->:SubOut:->] {
            if t.iri in subg_nodes {
                edge_set.add((iri, t.iri, "subClassOf"));
            }
        }
        for t in [concepts[iri] ->:SeeAlso:->] {
            if t.iri in subg_nodes {
                edge_set.add((iri, t.iri, "seeAlso"));
            }
        }
    }
    return {
        "nodes": sorted(subg_nodes),
        "edges": sorted(edge_set),
        "truncated": subg_truncated,
    };
}

test "bounded neighbourhood with seeAlso and truncation" {
    add_concept("obo:GO_0055114", "oxidation-reduction");
    add_concept("obo:GO_0008152", "metabolic process");
    add_concept("obo:GO_0003674", "molecular_function");
    add_concept("obo:HP_0000001", "all");
    add_edge("obo:GO_0055114", "obo:GO_0008152", "subClassOf");
    add_edge("obo:GO_0008152", "obo:HP_0000001", "subClassOf");
    add_edge("obo:GO_0055114", "obo:GO_0003674", "seeAlso");

    res = build_subgraph("obo:GO_0055114");
    assert res["nodes"] == ["obo:GO_0003674", "obo:GO_0008152",
                            "obo:GO_0055114", "obo:HP_0000001"], res["nodes"];
    assert ("obo:GO_0055114", "obo:GO_0008152", "subClassOf") in res["edges"];
    assert ("obo:GO_0055114", "obo:GO_0003674", "seeAlso") in res["edges"];
    assert not res["truncated"];

    res2 = build_subgraph("obo:GO_0055114", include_see_also=False);
    assert "obo:GO_0003674" not in res2["nodes"];
}

test "node budget triggers truncation flag" {
    for i in range(6) {
        add_concept("c{}".format(i));
        if i > 0 {
            add_edge("c0", "c{}".format(i), "seeAlso");
        }
    }
    tight = build_subgraph("c0", descendants_depth=1, max_nodes=3);
    assert tight["nodes"] == ["c0", "c1", "c2"], tight["nodes"];
    assert tight["truncated"], "expected truncation";
    roomy = build_subgraph("c0", descendants_depth=1);
    assert len(roomy["nodes"]) == 6 and not roomy["truncated"];
}

test "depth limits hold" {
    for i in range(5) {
        add_concept("d{}".format(i));
        if i > 0 {
            add_edge("d{}", "d{}".format(i)) if False else None;
            add_edge("d{}".format(i - 1), "d{}".format(i), "subClassOf");
        }
    }
    shallow = build_subgraph("d0", ancestors_depth=1, descendants_depth=1,
                             include_see_also=False);
    assert sorted(shallow["nodes"]) == ["d0", "d1"], shallow["nodes"];
}

test "cycle-safe traversal and errors" {
    add_concept("l0");
    add_concept("l1");
    add_edge("l0", "l1", "subClassOf");
    # hostile back edge: l1 asserted as superclass of itself-adjacent pair
    concepts["l0"] +>:SubIn:+> concepts["l1"];
    out = build_subgraph("l0");
    assert out["nodes"] == ["l0", "l1"], out;
    try {
        build_subgraph("missing");
        assert False;
    } except KeyError {
        assert True;
    }
    try {
        add_edge("l0", "l1", "partOf");
        assert False;
    } except ValueError {
        assert True;
    }
}
