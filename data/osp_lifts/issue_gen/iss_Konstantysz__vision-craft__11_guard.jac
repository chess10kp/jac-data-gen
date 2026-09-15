"""Konstantysz/vision-craft#11 — cycle detection in node graph."""

node N {
    has cid: str;
}

edge Dep {}

obj GraphEditor {
    has nodes: dict[str, N] = {};
    has graph_root: N;

    def ensure_node(self, cid: str) -> N {
        if cid in self.nodes {
            return self.nodes[cid];
        }
        nd = N(cid=cid);
        self.nodes[cid] = nd;
        if not self.graph_root {
            self.graph_root = nd;
        }
        return nd;
    }

    def add_edge(self, src_id: str, dst_id: str) {
        src = self.ensure_node(src_id);
        dst = self.ensure_node(dst_id);
        src +>:Dep:+> dst;
    }

    def get_node(self, node_id: str) -> N | None {
        if node_id in self.nodes {
            return self.nodes[node_id];
        }
        return None;
    }
}

def build_editor(edge_pairs: list[list[str]]) -> GraphEditor {
    ed = GraphEditor();
    for pair in edge_pairs {
        ed.add_edge(pair[0], pair[1]);
    }
    return ed;
}

def detect_cycles(editor: GraphEditor) -> list[str] {
    if not editor.graph_root {
        empty: list[str] = [];
        return empty;
    }
    global_claimed: dict[str, bool] = {};
    node_ids: list[str] = [];
    for cid in editor.nodes {
        node_ids.append(cid);
    }
    node_ids = sorted(node_ids);
    result: list[str] = [];
    for nid in node_ids {
        if nid in global_claimed {
            continue;
        }
        nd = editor.nodes[nid];
        w = nd spawn CycleProbe(
            claimed=global_claimed,
            on_path={},
            path=[],
            found=[],
            done=False
        );
        if len(w.found) > 0 {
            result = w.found;
            break;
        }
    }
    print "detect_cycles:";
    print result;
    return result;
}

def detect_cycles_from(editor: GraphEditor, start_id: str) -> list[str] {
    if start_id not in editor.nodes {
        empty: list[str] = [];
        return empty;
    }
    nd = editor.nodes[start_id];
    w = nd spawn CycleProbe(
        claimed={},
        on_path={},
        path=[],
        found=[],
        done=False
    );
    print "detect_cycles_from:";
    print start_id;
    print w.found;
    return w.found;
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has on_path: dict[str, bool] = {};
    has path: list[str] = [];
    has found: list[str] = [];
    has done: bool = False;

    can step with N entry {
        if self.done {
            skip;
        }
        cid = here.cid;
        if cid in self.on_path {
            start_idx = 0;
            for i in range(len(self.path)) {
                if self.path[i] == cid {
                    start_idx = i;
                }
            }
            cyc: list[str] = [];
            for j in range(start_idx, len(self.path)) {
                cyc.append(self.path[j]);
            }
            cyc.append(cid);
            self.found = cyc;
            self.done = True;
            print "cycle:";
            print cyc;
            skip;
        }
        if cid in self.claimed {
            skip;
        }
        self.claimed[cid] = True;
        self.on_path[cid] = True;
        self.path.append(cid);
        kids: list[N] = [here ->:Dep:->][?:N];
        if len(kids) > 0 {
            for ch in kids {
                visit :0: [ch];
            }
        } else {
            disengage;
        }
        if cid in self.on_path {
            self.on_path.pop(cid);
        }
        if len(self.path) > 0 {
            self.path.pop();
        }
        disengage;
    }
}

test "empty_graph_no_cycles" {
    ed = build_editor([]);
    result = detect_cycles(ed);
    assert len(result) == 0;
}

test "acyclic_chain_no_cycles" {
    ed = build_editor([["a", "b"], ["b", "c"]]);
    result = detect_cycles(ed);
    assert len(result) == 0;
}

test "triangle_cycle_detected" {
    ed = build_editor([["a", "b"], ["b", "c"], ["c", "a"]]);
    result = detect_cycles(ed);
    assert len(result) == 4;
    assert result[0] == "a";
    assert result[1] == "b";
    assert result[2] == "c";
    assert result[3] == "a";
}

test "detect_from_unknown_id_empty" {
    ed = build_editor([["a", "b"]]);
    result = detect_cycles_from(ed, "missing");
    assert len(result) == 0;
}

test "detect_from_midpoint_cycle" {
    ed = build_editor([["x", "y"], ["y", "z"], ["z", "x"]]);
    result = detect_cycles_from(ed, "y");
    assert len(result) == 4;
    assert result[0] == "y";
    assert result[3] == "y";
}

test "self_loop_cycle" {
    ed = build_editor([["solo", "solo"]]);
    result = detect_cycles_from(ed, "solo");
    assert len(result) == 2;
    assert result[0] == "solo";
    assert result[1] == "solo";
}
