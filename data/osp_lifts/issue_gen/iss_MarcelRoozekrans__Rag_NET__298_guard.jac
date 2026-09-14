"""MarcelRoozekrans/Rag.NET#298 — graph backend and traversal model."""

node Document {
    has key: str;
    has title: str = "";
}

edge Relationship {}

obj GraphStore {
    has backend: str = "sqlite";
    has durable: bool = False;
    has location: str = ":memory:";
    has collation_indexed: bool = False;
    has documents: dict[str, Document] = {};
}

walker NeighborWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can inspect with Document entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        print(here.key);
        for kid in [here ->:Relationship:->][?:Document] {
            self.found.append(kid.key);
        }
    }
}

walker ReachabilityWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can explore with Document entry {
        if here.key in self.claimed {
            skip;
        }
        self.claimed[here.key] = True;
        self.found.append(here.key);
        print(here.key);
        for kid in [here ->:Relationship:->][?:Document] {
            visit :0: [kid];
        }
    }
}

def new_graph(backend: str = "sqlite", durable: bool = False) -> GraphStore {
    graph = GraphStore(backend=backend, durable=durable);
    if durable {
        graph.location = "graph.db";
    }
    return graph;
}

def add_document(graph: GraphStore, node_id: str, title: str = "") -> bool {
    if node_id in graph.documents {
        return False;
    }
    doc = Document(key=node_id, title=title);
    graph.documents[node_id] = doc;
    return True;
}

def add_relationship(
    graph: GraphStore, source_id: str, target_id: str
) -> bool {
    source: Document | None = None;
    target: Document | None = None;
    if source_id in graph.documents {
        source = graph.documents[source_id];
    }
    if target_id in graph.documents {
        target = graph.documents[target_id];
    }
    if source == None {
        return False;
    }
    if target == None {
        return False;
    }
    source +>:Relationship:+> target;
    return True;
}

def get_neighbors(graph: GraphStore, node_id: str) -> list[str] {
    start: Document | None = None;
    if node_id in graph.documents {
        start = graph.documents[node_id];
    }
    if start == None {
        return [];
    }
    w = start spawn NeighborWalk(claimed={});
    return sorted(w.found);
}

def reachable(graph: GraphStore, node_id: str) -> list[str] {
    start: Document | None = None;
    if node_id in graph.documents {
        start = graph.documents[node_id];
    }
    if start == None {
        return [];
    }
    w = start spawn ReachabilityWalk(claimed={});
    return sorted(w.found);
}

def apply_collation_index(graph: GraphStore) -> bool {
    graph.collation_indexed = True;
    return True;
}

def backend_guidance(graph: GraphStore) -> str {
    if graph.backend != "sqlite" {
        return "compare-with-sqlite";
    }
    if graph.collation_indexed {
        return "indexed-remeasure-before-backend";
    }
    return "fix-297-and-remeasure";
}

test "diamond revisit is claimed once" {
    graph = new_graph();
    assert (add_document(graph, "a"));
    assert (add_document(graph, "b"));
    assert (add_document(graph, "c"));
    assert (add_document(graph, "d"));
    assert (add_document(graph, "e"));
    assert (add_relationship(graph, "a", "c"));
    assert (add_relationship(graph, "a", "b"));
    assert (add_relationship(graph, "c", "d"));
    assert (add_relationship(graph, "b", "d"));
    assert (add_relationship(graph, "d", "e"));
    assert (reachable(graph, "a") == ["a", "b", "c", "d", "e"]);
    assert (get_neighbors(graph, "a") == ["b", "c"]);
}

test "unknown identifiers are tolerated" {
    graph = new_graph();
    assert (get_neighbors(graph, "missing") == []);
    assert (reachable(graph, "missing") == []);
    assert (add_relationship(graph, "missing", "other") == False);
}

test "sqlite defaults expose the measured decision" {
    graph = new_graph();
    assert (graph.backend == "sqlite");
    assert (graph.location == ":memory:");
    assert (backend_guidance(graph) == "fix-297-and-remeasure");
    assert (apply_collation_index(graph));
    assert (backend_guidance(graph) == "indexed-remeasure-before-backend");
}

test "self cycles and duplicate documents are safe" {
    graph = new_graph("postgres", True);
    assert (graph.location == "graph.db");
    assert (add_document(graph, "solo"));
    assert (add_document(graph, "solo") == False);
    assert (add_relationship(graph, "solo", "solo"));
    assert (get_neighbors(graph, "solo") == ["solo"]);
    assert (reachable(graph, "solo") == ["solo"]);
    assert (backend_guidance(graph) == "compare-with-sqlite");
}
