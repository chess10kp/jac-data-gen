node ContextItem {
    has id: str;
    has node_type: str;
    has label: str;
    has properties: dict[str, str] = {};
    has references: list[str] = [];
    has depends_on: list[str] = [];
    has contradicts: list[str] = [];
    has supports: list[str] = [];
    has derived_from: list[str] = [];
    has part_of: list[str] = [];
    has implements: list[str] = [];
}

node KnowledgeGraph {}

node KnowledgeNode {
    has id: str;
    has context_item_id: str;
    has node_type: str;
    has label: str;
    has properties: dict[str, str] = {};
}

edge Contains {}
edge KnowledgeEdge {
    has relation_type: str = "RelatedTo";
    has weight: float = 1.0;
    has properties: dict[str, str] = {};
}
edge DependsOn {}
edge Contradicts {}
edge Supports {}
edge DerivedFrom {}
edge PartOf {}
edge Implements {}

def find_node(graph_root: KnowledgeGraph, node_id: str) -> KnowledgeNode | None {
    for nd in [graph_root ->:Contains:->][?:KnowledgeNode] {
        if nd.id == node_id {
            return nd;
        }
    }
    return None;
}

def connect_relation(source: KnowledgeNode, target: KnowledgeNode, relation: str) {
    if relation == "RelatedTo" {
        source +>:KnowledgeEdge:+> target;
    } elif relation == "DependsOn" {
        source +>:DependsOn:+> target;
    } elif relation == "Contradicts" {
        source +>:Contradicts:+> target;
    } elif relation == "Supports" {
        source +>:Supports:+> target;
    } elif relation == "DerivedFrom" {
        source +>:DerivedFrom:+> target;
    } elif relation == "PartOf" {
        source +>:PartOf:+> target;
    } elif relation == "Implements" {
        source +>:Implements:+> target;
    }
}

def path_plus(path: list[str], relation: str) -> list[str] {
    result: list[str] = [];
    for item in path {
        result.append(item);
    }
    result.append(relation);
    return result;
}

walker RelatedWalker {
    has max_depth: int;
    has max_items: int;
    has claimed: dict[str, bool] = {};
    has path: list[str] = [];
    has found: list[tuple[KnowledgeNode, list[str], int]] = [];

    can walk_node with KnowledgeNode entry {
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        print(here.id);

        if len(self.path) > 0 {
            self.found.append((here, self.path, len(self.path)));
            if self.max_items > 0 and len(self.found) >= self.max_items {
                disengage;
            }
        }
        if len(self.path) >= self.max_depth {
            return;
        }

        for kid in [here ->:KnowledgeEdge:->][?:KnowledgeNode] {
            self.path = path_plus(self.path, "RelatedTo");
            visit :0: [kid];
        }
        for kid in [here ->:DependsOn:->][?:KnowledgeNode] {
            self.path = path_plus(self.path, "DependsOn");
            visit :0: [kid];
        }
        for kid in [here ->:Contradicts:->][?:KnowledgeNode] {
            self.path = path_plus(self.path, "Contradicts");
            visit :0: [kid];
        }
        for kid in [here ->:Supports:->][?:KnowledgeNode] {
            self.path = path_plus(self.path, "Supports");
            visit :0: [kid];
        }
        for kid in [here ->:DerivedFrom:->][?:KnowledgeNode] {
            self.path = path_plus(self.path, "DerivedFrom");
            visit :0: [kid];
        }
        for kid in [here ->:PartOf:->][?:KnowledgeNode] {
            self.path = path_plus(self.path, "PartOf");
            visit :0: [kid];
        }
        for kid in [here ->:Implements:->][?:KnowledgeNode] {
            self.path = path_plus(self.path, "Implements");
            visit :0: [kid];
        }
    }
}

def build(items: list[ContextItem]) -> KnowledgeGraph {
    graph_root = KnowledgeGraph();

    for item in items {
        nd = KnowledgeNode(
            id=item.id,
            context_item_id=item.id,
            node_type=item.node_type,
            label=item.label,
            properties=item.properties
        );
        graph_root +>:Contains:+> nd;
    }

    for item in items {
        source: KnowledgeNode | None = find_node(graph_root, item.id);
        if source != None {
            for target_id in item.references {
                target: KnowledgeNode | None = find_node(graph_root, target_id);
                if target != None {
                    connect_relation(source, target, "RelatedTo");
                }
            }
            for target_id in item.depends_on {
                target = find_node(graph_root, target_id);
                if target != None {
                    connect_relation(source, target, "DependsOn");
                }
            }
            for target_id in item.contradicts {
                target = find_node(graph_root, target_id);
                if target != None {
                    connect_relation(source, target, "Contradicts");
                }
            }
            for target_id in item.supports {
                target = find_node(graph_root, target_id);
                if target != None {
                    connect_relation(source, target, "Supports");
                }
            }
            for target_id in item.derived_from {
                target = find_node(graph_root, target_id);
                if target != None {
                    connect_relation(source, target, "DerivedFrom");
                }
            }
            for target_id in item.part_of {
                target = find_node(graph_root, target_id);
                if target != None {
                    connect_relation(source, target, "PartOf");
                }
            }
            for target_id in item.implements {
                target = find_node(graph_root, target_id);
                if target != None {
                    connect_relation(source, target, "Implements");
                }
            }
        }
    }
    return graph_root;
}

def get_related(
    graph: KnowledgeGraph,
    node_id: str,
    max_depth: int,
    max_items: int
) -> list[tuple[KnowledgeNode, list[str], int]] {
    start: KnowledgeNode | None = find_node(graph, node_id);
    if start == None {
        return [];
    }
    w = start spawn RelatedWalker(
        max_depth=max_depth,
        max_items=max_items,
        claimed={}
    );
    return w.found;
}

test "diamond revisit is claimed once" {
    items: list[ContextItem] = [];
    items.append(ContextItem(id="a", node_type="Concept", label="A", references=["b", "c"]));
    items.append(ContextItem(id="b", node_type="Concept", label="B", references=["d"]));
    items.append(ContextItem(id="c", node_type="Concept", label="C", references=["d"]));
    items.append(ContextItem(id="d", node_type="Fact", label="D"));
    graph = build(items);
    got = get_related(graph, "a", 3, 10);
    ids: list[str] = [];
    for hit in got {
        ids.append(hit[0].id);
    }
    assert (sorted(ids) == ["b", "c", "d"]);
    assert (len(ids) == 3);
}

test "unknown node returns empty results" {
    items: list[ContextItem] = [];
    items.append(ContextItem(id="a", node_type="Concept", label="A"));
    graph = build(items);
    assert (len(get_related(graph, "missing", 4, 10)) == 0);
}

test "depth and item limits are enforced" {
    items: list[ContextItem] = [];
    items.append(ContextItem(id="a", node_type="Concept", label="A", references=["b"]));
    items.append(ContextItem(id="b", node_type="Concept", label="B", references=["c"]));
    items.append(ContextItem(id="c", node_type="Concept", label="C"));
    graph = build(items);
    assert (len(get_related(graph, "a", 1, 10)) == 1);
    assert (len(get_related(graph, "a", 5, 1)) == 1);
}

test "relationship types are preserved" {
    items: list[ContextItem] = [];
    items.append(ContextItem(id="a", node_type="Decision", label="A", depends_on=["b"]));
    items.append(ContextItem(id="b", node_type="Requirement", label="B"));
    graph = build(items);
    got = get_related(graph, "a", 2, 10);
    assert (len(got) == 1);
    assert (got[0][1][0] == "DependsOn");
}

test "self and missing references are harmless" {
    items: list[ContextItem] = [];
    items.append(ContextItem(id="a", node_type="Concept", label="A", references=["a", "missing"]));
    graph = build(items);
    assert (len(get_related(graph, "a", 2, 10)) == 0);
}
