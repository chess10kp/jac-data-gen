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
