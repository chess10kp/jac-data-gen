"""Graph export utilities — SkepticMystic/graph-analysis#42."""

node Note {
    has nid: str;
    has label: str = "";
}

edge Cite {}

node GraphHub {
    has members: dict[str, Note] = {};
}

walker BfsSpan {
    has claimed: dict[str, bool] = {};
    has edges_out: list[list[str]] = [];
    has parent: dict[str, str] = {};

    can grow with Note entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print({"bfs_visit": here.nid});
        kids: list[Note] = [];
        for ch in [here ->:Cite:->][?:Note] {
            kids.append(ch);
        }
        for i in range(len(kids)) {
            for j in range(i + 1, len(kids)) {
                if kids[j].nid < kids[i].nid {
                    tmp = kids[i];
                    kids[i] = kids[j];
                    kids[j] = tmp;
                }
            }
        }
        for ch in kids {
            if ch.nid not in self.parent {
                self.parent[ch.nid] = here.nid;
                self.edges_out.append([here.nid, ch.nid]);
            }
            if ch.nid not in self.claimed {
                visit [ch];
            }
        }
    }
}

walker ExportProbe {
    has claimed: dict[str, bool] = {};

    can hub_tour with GraphHub entry {
        print({"probe": "hub"});
        for nid in sorted(here.members.keys()) {
            if nid in here.members {
                nd = here.members[nid] as Note;
                if nd.nid in self.claimed { skip; }
                self.claimed[nd.nid] = True;
                print({"probe_visit": nd.nid});
                visit :0: [nd];
            }
        }
    }

    can note_step with Note entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print({"probe_note": here.nid});
        for ch in [here ->:Cite:->][?:Note] {
            visit :0: [ch];
        }
    }
}

def make_graph(node_rows: list[list[str]], edge_rows: list[list[str]]) -> GraphHub {
    hub = GraphHub(members={});
    index: dict[str, Note] = {};
    for row in node_rows {
        nid = row[0] as str;
        lbl = row[1] as str;
        nd = Note(nid=nid, label=lbl);
        index[nid] = nd;
        hub.members[nid] = nd;
    }
    for erow in edge_rows {
        a = erow[0] as str;
        b = erow[1] as str;
        if a in index and b in index {
            na = index[a] as Note;
            nb = index[b] as Note;
            na +>:Cite:+> nb;
            nb +>:Cite:+> na;
        }
    }
    root ++> hub;
    return hub;
}

def export_edge_list(hub: GraphHub) -> list[list[str]] {
    pairs: list[list[str]] = [];
    seen: dict[str, bool] = {};
    for nid in sorted(hub.members.keys()) {
        if nid not in hub.members { continue; }
        nd = hub.members[nid] as Note;
        for tgt in [nd ->:Cite:->][?:Note] {
            lo = nid;
            hi = tgt.nid;
            if hi < lo {
                lo = tgt.nid;
                hi = nid;
            }
            key = lo + "|" + hi;
            if key not in seen {
                seen[key] = True;
                pairs.append([lo, hi]);
            }
        }
    }
    pairs.sort();
    return pairs;
}

def export_adjacency(hub: GraphHub, order: list[str] | None = None) -> list[any] {
    ids: list[str] = [];
    if order is not None {
        for x in order {
            xs = x as str;
            if xs in hub.members { ids.append(xs); }
        }
    } else {
        for k in sorted(hub.members.keys()) { ids.append(k); }
    }
    n = len(ids);
    mat: list[list[int]] = [];
    for i in range(n) {
        row: list[int] = [];
        for j in range(n) { row.append(0); }
        mat.append(row);
    }
    pos: dict[str, int] = {};
    for i in range(n) {
        pos[ids[i] as str] = i;
    }
    for erow in export_edge_list(hub) {
        a = erow[0] as str;
        b = erow[1] as str;
        if a in pos and b in pos {
            ia = pos[a];
            ib = pos[b];
            mat[ia][ib] = 1;
            mat[ib][ia] = 1;
        }
    }
    return [ids, mat];
}

def bfs_spanning_edges(hub: GraphHub, start_id: str) -> list[list[str]] {
    if start_id not in hub.members { return []; }
    start_nd = hub.members[start_id] as Note;
    wk = start_nd spawn BfsSpan(claimed={}, edges_out=[], parent={});
    out: list[list[str]] = [];
    for row in wk.edges_out {
        out.append(row);
    }
    return out;
}

with entry {
    seed_nodes = [["a", "Alpha"], ["b", "Beta"]];
    seed_edges = [["a", "b"]];
    graph_hub = make_graph(seed_nodes, seed_edges);
    print(export_edge_list(graph_hub));
    root spawn ExportProbe;
}

test "export_edge_list_dedup_and_sort" {
    hub = make_graph(
        [["a", ""], ["b", ""], ["c", ""]],
        [["a", "b"], ["b", "c"], ["a", "c"]]
    );
    assert export_edge_list(hub) == [["a", "b"], ["a", "c"], ["b", "c"]];;
}

test "export_adjacency_default_order" {
    hub = make_graph(
        [["c", ""], ["a", ""], ["b", ""]],
        [["a", "b"], ["b", "c"]]
    );
    got = export_adjacency(hub);
    assert got[0] == ["a", "b", "c"];;
    assert got[1] == [[0, 1, 0], [1, 0, 1], [0, 1, 0]];;
}

test "export_adjacency_custom_order" {
    hub = make_graph(
        [["a", ""], ["b", ""], ["c", ""]],
        [["a", "b"], ["c", "b"]]
    );
    got = export_adjacency(hub, ["c", "a", "b"]);
    assert got[0] == ["c", "a", "b"];;
    assert got[1] == [[0, 0, 1], [0, 0, 1], [1, 1, 0]];;
}

test "bfs_spanning_edges_from_start" {
    hub = make_graph(
        [["a", ""], ["b", ""], ["c", ""]],
        [["a", "b"], ["b", "c"], ["a", "c"]]
    );
    assert bfs_spanning_edges(hub, "a") == [["a", "b"], ["a", "c"]];;
}

test "bfs_spanning_edges_missing_start" {
    hub = make_graph([["a", ""]], []);
    assert bfs_spanning_edges(hub, "z") == [];;
}

test "make_graph_ignores_unknown_edge_endpoints" {
    hub = make_graph([["a", ""], ["b", ""]], [["a", "b"], ["a", "z"]]);
    assert export_edge_list(hub) == [["a", "b"]];;
}
