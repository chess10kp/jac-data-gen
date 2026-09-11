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
