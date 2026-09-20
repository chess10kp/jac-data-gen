"""Recursive ancestor depth walk — sqlc-dev/sqlc#2390."""

node GraphNode {
    has cid: str;
    has name: str;
    has kind: str = "";
}

edge DepEdge {
    has ordinal: int = 0;
}

obj GraphHandle {
    has anchor: GraphNode;
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has rows: list[tuple[str, int]] = [];
    has node_depth: int = -1;

    can ascend with GraphNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;

        record_depth: int = self.node_depth + 1;
        if self.node_depth < 0 {
            record_depth = 0;
        }

        parents: list[GraphNode] = [];
        for par in [here <-:DepEdge:<-][?:GraphNode] {
            parents.append(par);
        }

        for par in parents {
            if not (par.cid in self.claimed) {
                self.rows.append((par.cid, record_depth));
            }
        }

        next_visits: list[GraphNode] = [];
        for par in parents {
            if not (par.cid in self.claimed) {
                next_visits.append(par);
            }
        }

        print("ascend", here.cid, record_depth, len(next_visits));

        if next_visits {
            self.node_depth = record_depth;
            visit :0: next_visits;
        } else {
            disengage;
        }
    }
}

def sort_rows(rows: list[tuple[str, int]]) -> list[tuple[str, int]] {
    keyed: list[tuple[int, str]] = [];
    for row in rows {
        keyed.append((row[1], row[0]));
    }
    keyed_sorted = sorted(keyed);
    out: list[tuple[str, int]] = [];
    for k in keyed_sorted {
        out.append((k[1], k[0]));
    }
    return out;
}

def resolve_node(g: GraphHandle, node_id: str) -> GraphNode | None {
    found: GraphNode | None = None;
    for nd in [g.anchor ->][?:GraphNode] {
        if nd.cid == node_id {
            found = nd;
        }
    }
    return found;
}

def build_graph(
    node_specs: list[tuple[str, str, str]],
    edge_specs: list[tuple[str, str, int]],
) -> GraphHandle {
    graph_root = GraphNode(cid="__graph__", name="graph", kind="meta");
    root ++> graph_root;
    nodes: dict[str, GraphNode] = {};
    for spec in node_specs {
        cid: str = spec[0];
        nm: str = spec[1];
        kd: str = spec[2];
        nd = GraphNode(cid=cid, name=nm, kind=kd);
        nodes[cid] = nd;
        graph_root ++> nd;
    }
    for spec in edge_specs {
        p_id: str = spec[0];
        c_id: str = spec[1];
        ordv: int = spec[2];
        p_nd = nodes[p_id];
        c_nd = nodes[c_id];
        p_nd +>:DepEdge(ordinal=ordv):+> c_nd;
    }
    return GraphHandle(anchor=graph_root);
}

def get_node(g: GraphHandle, node_id: str) -> GraphNode | None {
    return resolve_node(g, node_id);
}

def get_dependent_nodes(g: GraphHandle, child_id: str) -> list[tuple[str, int]] {
    start: GraphNode | None = resolve_node(g, child_id);
    if not start {
        return [];
    }
    w = start spawn AncestorWalk();
    print("dependent_nodes", child_id, len(w.rows));
    return sort_rows(w.rows);
}
