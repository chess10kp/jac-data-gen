"""abdullahbodur/horo-engine#2053 — DAG/pin/cycle/limit validation with stable diagnostics."""

class GraphValidationError(Exception) {}

node WfAnchor {}

node WfNode {
    has nid: str;
    has pins: dict[str, str] = {};
}

edge WfLink: WfNode --> WfNode {
    has src_pin: str;
    has dst_pin: str;
}

def sort_wf(items: list[WfNode]) -> list[WfNode] {
    names: list[str] = [];
    for it in items { names.append(it.nid); }
    names = sorted(names);
    out: list[WfNode] = [];
    for nm in names {
        for it in items {
            if it.nid == nm { out.append(it); }
        }
    }
    return out;
}

walker TopoRound {
    has indeg: dict[str, int] = {};
    has picked: list[str] = [];

    can start with WfAnchor entry { visit [-->][?:WfNode]; }

    can on_node with WfNode entry {
        if self.indeg.get(here.nid, 0) < 0 { skip; }
        if self.indeg.get(here.nid, 0) > 0 { skip; }
        self.picked.append(here.nid);
    }
}

walker CycleWalk {
    has stack: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has cycle: list[str] = [];
    has got: bool = False;

    can start with WfAnchor entry { visit [-->][?:WfNode]; }

    can on_node with WfNode entry {
        if self.got { skip; }
        nid = here.nid;
        if nid in self.stack {
            chain: list[str] = [nid];
            cur = self.parent.get(nid, "");
            while cur != nid and cur != "" {
                chain.append(cur);
                cur = self.parent.get(cur, "");
            }
            chain.reverse();
            self.cycle = chain;
            self.got = True;
            skip;
        }
        if nid in self.parent { skip; }
        self.stack[nid] = True;
        succs = sort_wf([here ->:WfLink:->]);
        for s in succs {
            if s.nid not in self.parent { self.parent[s.nid] = nid; }
            visit [s];
        }
        del self.stack[nid];
    }
}

obj WorkflowValidator {
    has anchor: WfAnchor;
    has limits: dict[str, int] = {};
    has node_limits: dict[str, int] = {};

    def init {
        self.limits = {};
        self.node_limits = {};
        self.anchor = WfAnchor();
        root ++> self.anchor;
    }

    def _find(nid: str) -> WfNode | None {
        for nd in [self.anchor -->][?:WfNode] {
            if nd.nid == nid { return nd; }
        }
        return None;
    }

    def _topo_pick() -> list[str] {
        indeg: dict[str, int] = {};
        for nd in [self.anchor -->][?:WfNode] {
            indeg[nd.nid] = len([nd <-:WfLink:<-]);
        }
        order: list[str] = [];
        total = len(indeg);
        while len(order) < total {
            w = self.anchor spawn TopoRound(indeg=indeg, picked=[]);
            if len(w.picked) == 0 { return order; }
            round_pick = sorted(w.picked);
            for nid in round_pick {
                order.append(nid);
                nd = self._find(nid);
                if nd is not None {
                    for succ in [nd ->:WfLink:->] {
                        indeg[succ.nid] = indeg.get(succ.nid, 0) - 1;
                    }
                }
                indeg[nid] = -1;
            }
        }
        return order;
    }

    def add_node(node_id: str, outputs: dict[str, str]) {
        if self._find(node_id) is not None { raise GraphValidationError("duplicate node id"); }
        nd = WfNode(nid=node_id, pins=dict(outputs));
        self.anchor ++> nd;
    }

    def add_edge(src: tuple[str, str], dst: tuple[str, str]) {
        s_node = self._find(src[0]);
        d_node = self._find(dst[0]);
        if s_node is None or d_node is None { raise GraphValidationError("dangling edge"); }
        if src[1] not in s_node.pins { raise GraphValidationError("incompatible pin"); }
        if dst[1] not in d_node.pins { raise GraphValidationError("incompatible pin"); }
        if s_node.pins[src[1]] != d_node.pins[dst[1]] {
            raise GraphValidationError("incompatible pin");
        }
        s_node +>:WfLink(src_pin=src[1], dst_pin=dst[1]):+> d_node;
    }

    def set_graph_limit(name: str, max_count: int) { self.limits[name] = max_count; }

    def set_node_budget(node_id: str, max_instances: int) {
        self.node_limits[node_id] = max_instances;
    }

    def detect_cycle() -> list[str] | None {
        total = len([self.anchor -->][?:WfNode]);
        order = self._topo_pick();
        if len(order) == total { return None; }
        w = self.anchor spawn CycleWalk(stack={}, parent={}, cycle=[], got=False);
        if len(w.cycle) > 0 { return w.cycle; }
        names: list[str] = [];
        for nd in sort_wf([self.anchor -->][?:WfNode]) { names.append(nd.nid); }
        return names;
    }

    def validate() -> list[str] {
        diags: list[str] = [];
        node_count = len([self.anchor -->][?:WfNode]);
        lim = self.limits.get("nodes", 1000000000);
        if node_count > lim { diags.append("limit:nodes exceeded"); }
        keys = sorted(self.node_limits.keys());
        for nid in keys {
            cap = self.node_limits[nid];
            if cap < 0 { diags.append(f"limit:node:{nid} invalid"); }
        }
        cyc = self.detect_cycle();
        if cyc is not None {
            parts: list[str] = [];
            for c in cyc { parts.append(c); }
            diags.append("cycle:" + ">".join(parts));
        }
        return sorted(diags);
    }

    def topological_order() -> list[str] {
        if self.detect_cycle() is not None { raise GraphValidationError("cycle detected"); }
        return self._topo_pick();
    }
}

test "diamond topological_order with adversarial link order" {
    v = WorkflowValidator();
    v.add_node("A", {"out": "float"});
    v.add_node("B", {"in": "float", "out": "float"});
    v.add_node("C", {"in": "float", "out": "float"});
    v.add_node("D", {"in": "float"});
    v.add_edge(("A", "out"), ("C", "in"));
    v.add_edge(("A", "out"), ("B", "in"));
    v.add_edge(("C", "out"), ("D", "in"));
    v.add_edge(("B", "out"), ("D", "in"));
    assert v.detect_cycle() is None;
    assert v.topological_order() == ["A", "B", "C", "D"];
}

test "validate reports limit and cycle diagnostics together" {
    v = WorkflowValidator();
    v.set_graph_limit("nodes", 1);
    v.add_node("X", {"o": "int"});
    v.add_node("Y", {"i": "int", "o": "int"});
    v.add_edge(("X", "o"), ("Y", "i"));
    v.add_edge(("Y", "o"), ("X", "o"));
    cyc = v.detect_cycle();
    assert cyc is not None;
    assert v.validate() == sorted(["limit:nodes exceeded", "cycle:" + ">".join(cyc)]);
}

test "add_edge rejects missing source pin" {
    v = WorkflowValidator();
    v.add_node("N", {"a": "float"});
    raised = False;
    try {
        v.add_edge(("N", "missing"), ("N", "a"));
        assert False, "should have raised";
    } except GraphValidationError as e {
        assert str(e) == "incompatible pin";
        raised = True;
    }
    assert raised;
}

test "add_edge rejects missing destination pin" {
    v = WorkflowValidator();
    v.add_node("P", {"x": "float"});
    v.add_node("Q", {"y": "float"});
    raised = False;
    try {
        v.add_edge(("P", "x"), ("Q", "missing"));
        assert False, "should have raised";
    } except GraphValidationError as e {
        assert str(e) == "incompatible pin";
        raised = True;
    }
    assert raised;
}

test "detect_cycle finds two-node cycle" {
    v = WorkflowValidator();
    v.add_node("U", {"o": "int", "i": "int"});
    v.add_node("V", {"i": "int", "o": "int"});
    v.add_edge(("U", "o"), ("V", "i"));
    v.add_edge(("V", "o"), ("U", "i"));
    cyc = v.detect_cycle();
    assert cyc is not None;
    assert v.validate() == ["cycle:" + ">".join(cyc)];
}

test "set_node_budget negative emits deterministic diagnostic" {
    v = WorkflowValidator();
    v.add_node("M", {"o": "float"});
    v.set_node_budget("M", -1);
    assert v.validate() == ["limit:node:M invalid"];
}
