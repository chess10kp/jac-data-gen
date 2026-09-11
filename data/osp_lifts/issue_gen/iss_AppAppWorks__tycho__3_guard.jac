"""Guard: AppAppWorks/tycho#3."""

node DagNode { has name: str; }
edge ParentOf {}

obj DagStore {
    has nodes: dict[str, DagNode] = {};

    def add_node(name: str, parent: str | None = None) {
        if parent is not None and self.nodes.get(parent, None) is None {
            raise KeyError("unknown parent");
        }
        n = DagNode(name=name);
        root ++> n;
        self.nodes[name] = n;
        if parent is not None {
            p = self.nodes.get(parent, None);
            if p is not None { p +>:ParentOf:+> n; }
        }
    }

    def dominates(u: str, v: str) -> bool {
        if self.nodes.get(u, None) is None or self.nodes.get(v, None) is None {
            return False;
        }
        if u == v { return True; }
        anc = self.ancestors(v);
        for a in anc {
            if a == u { return True; }
        }
        return False;
    }

    def ancestors(`node: str) -> list[str] {
        start = self.nodes.get(`node, None);
        if start is None { raise KeyError("unknown node"); }
        w = start spawn AncestorAscent(active={`node: True}, chain=[]);
        return sorted(w.chain);
    }
}

walker AncestorAscent {
    has active: dict[str, bool];
    has chain: list[str] = [];

    can step with DagNode entry {
        parents = [here <-:ParentOf:<-][?:DagNode];
        if len(parents) == 0 { disengage; }
        p = parents[0];
        if p.name in self.active { disengage; }
        self.active[p.name] = True;
        self.chain.append(p.name);
        visit [p];
    }
}

test "dominance and ancestors" {
    st = DagStore();
    st.add_node("S");
    st.add_node("NP", parent="S");
    st.add_node("VP", parent="S");
    st.add_node("N", parent="NP");
    st.add_node("V", parent="VP");
    assert st.dominates("S", "N") is True;
    assert st.dominates("NP", "V") is False;
    assert st.ancestors("N") == ["NP", "S"];
}

test "cycle tolerant ascent" {
    c = DagStore();
    c.add_node("a");
    c.add_node("b", parent="a");
    c.nodes["a"] +>:ParentOf:+> c.nodes["b"];
    c.nodes["b"] +>:ParentOf:+> c.nodes["a"];
    assert c.ancestors("a") == ["b"];
}

test "unknown node errors" {
    st = DagStore();
    try {
        st.ancestors("ghost");
        assert False;
    } except KeyError {
        assert True;
    }
    assert st.dominates("missing", "N") is False;
}
