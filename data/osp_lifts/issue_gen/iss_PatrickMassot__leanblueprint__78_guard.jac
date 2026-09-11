"""Dependency-graph ancestors with explicit cycle detection.

PatrickMassot/leanblueprint#78 lifted to OSP: labels become Doc node
archetypes; the ``_pred``/``_succ`` adjacency dicts collapse into one
typed Uses edge family (user -> used), read forward for predecessors and
backward for successors. The ancestor closure is a claim-map walker; a
cycle reachable from the origin re-visits the origin, which raises
CycleError. find_cycle is a deterministic single-path descent. The
payload of CycleError (the label path) is exposed through find_cycle
instead of the exception object.
"""
node Doc {
    has label: str;
}

edge Uses {}

class CycleError(ValueError) {}

obj GraphHandle {
    has docs: dict[str, Doc];

    def resolve(label: str) -> Doc | None {
        return self.docs.get(label);
    }
}

def build_graph(labels: list[str]) -> GraphHandle {
    g = GraphHandle(docs={});
    for lbl in labels {
        d = Doc(label=lbl);
        root ++> d;
        g.docs[lbl] = d;
    }
    return g;
}

def add_node(g: GraphHandle, label: str) {
    d = Doc(label=label);
    root ++> d;
    g.docs[label] = d;
}

def add_edge(g: GraphHandle, user: str, used: str) {
    u = g.resolve(user);
    d = g.resolve(used);
    if u is None or d is None {
        raise KeyError("unknown label");
    }
    u +>:Uses:+> d;
}

def predecessors(g: GraphHandle, label: str) -> list[str] {
    d = g.resolve(label);
    if d is None {
        raise KeyError("unknown label");
    }
    out: list[str] = [];
    targets: list[Doc] = [d ->:Uses:->];
    for t in targets {
        out.append(t.label);
    }
    return sorted(out);
}

def successors(g: GraphHandle, label: str) -> list[str] {
    d = g.resolve(label);
    if d is None {
        raise KeyError("unknown label");
    }
    out: list[str] = [];
    users: list[Doc] = [d <-:Uses:<-];
    for t in users {
        out.append(t.label);
    }
    return sorted(out);
}

# Claim-map closure over Uses edges; dedups diamonds. Reaching the origin
# again (first visit exempt) means the origin sits on a cycle.
walker AncClose {
    has claimed: dict[str, bool];
    has origin: str;
    has out: list[str] = [];
    has cyclic: bool = False;
    has first: bool = True;

    can step with Doc entry {
        if self.first {
            self.first = False;
        } else {
            if here.label == self.origin {
                self.cyclic = True;
                disengage;
            }
            if here.label in self.claimed {
                skip;
            }
            self.claimed[here.label] = True;
            self.out.append(here.label);
        }
        visit [->:Uses:->];
    }
}

# Deterministic single-path descent: follow Uses edges, tracking only
# this descent's path; first revisit closes the cycle.
walker PathWalk {
    has on_path: dict[str, bool];
    has path: list[str] = [];
    has cycle: list[str] = [];

    can step with Doc entry {
        if here.label in self.on_path {
            i = 0;
            while i < len(self.path) and self.path[i] != here.label {
                i += 1;
            }
            while i < len(self.path) {
                self.cycle.append(self.path[i]);
            }
            self.cycle.append(here.label);
            disengage;
        }
        self.on_path[here.label] = True;
        self.path.append(here.label);
        visit [->:Uses:->];
    }
}

def ancestors(g: GraphHandle, label: str) -> list[str] {
    d = g.resolve(label);
    if d is None {
        raise KeyError("unknown label");
    }
    w = d spawn AncClose(claimed={}, origin=label);
    if w.cyclic {
        raise CycleError("dependency cycle reachable from " + label);
    }
    return sorted(w.out);
}

def find_cycle(g: GraphHandle) -> list[str] {
    for lbl in g.docs.keys() {
        start = g.resolve(lbl);
        if start is not None {
            w = start spawn PathWalk(on_path={});
            if len(w.cycle) > 0 {
                return w.cycle;
            }
        }
    }
    return [];
}


test "acyclic ancestors closure and neighbor views" {
    g = build_graph(["thm1", "thm2", "thm3", "lem1", "lem2", "def1"]);
    add_edge(g, "thm1", "thm2");
    add_edge(g, "thm1", "lem1");
    add_edge(g, "thm2", "lem1");
    add_edge(g, "thm2", "lem2");
    add_edge(g, "lem1", "def1");
    assert predecessors(g, "thm2") == ["lem1", "lem2"];
    assert predecessors(g, "thm1") == ["lem1", "thm2"];
    assert successors(g, "lem1") == ["thm1", "thm2"];
    assert successors(g, "def1") == ["lem1"];
    assert ancestors(g, "thm1") == ["def1", "lem1", "lem2", "thm2"];
    assert ancestors(g, "lem1") == ["def1"];
    assert ancestors(g, "def1") == [];
    assert len(find_cycle(g)) == 0;
}

test "unknown labels raise KeyError" {
    g = build_graph(["a", "b"]);
    add_edge(g, "a", "b");
    raised = False;
    try {
        predecessors(g, "nope");
    } except KeyError {
        raised = True;
    }
    assert raised;
    raised = False;
    try {
        successors(g, "nope");
    } except KeyError {
        raised = True;
    }
    assert raised;
    raised = False;
    try {
        ancestors(g, "nope");
    } except KeyError {
        raised = True;
    }
    assert raised;
    raised = False;
    try {
        add_edge(g, "a", "nope");
    } except KeyError {
        raised = True;
    }
    assert raised;
}

test "cycle raises CycleError and find_cycle reports valid path" {
    g = build_graph(["thm1", "thm2", "thm3", "lem1", "lem2", "def1"]);
    add_edge(g, "thm1", "thm2");
    add_edge(g, "thm1", "lem1");
    add_edge(g, "thm2", "lem1");
    add_edge(g, "thm2", "lem2");
    add_edge(g, "lem1", "def1");
    add_edge(g, "lem2", "thm1");
    raised = False;
    try {
        ancestors(g, "thm1");
    } except CycleError {
        raised = True;
    }
    assert raised;
    raised = False;
    try {
        ancestors(g, "lem2");
    } except CycleError {
        raised = True;
    }
    assert raised;
    cyc = find_cycle(g);
    assert len(cyc) > 1;
    assert cyc[0] == cyc[len(cyc) - 1];
    i = 0;
    while i < len(cyc) - 1 {
        nxt = cyc[i + 1];
        assert nxt in predecessors(g, cyc[i]);
        i += 1;
    }
}

test "diamond with shortcut stays acyclic once-only" {
    g = build_graph(["a", "b", "c", "d", "e"]);
    add_edge(g, "a", "b");
    add_edge(g, "a", "c");
    add_edge(g, "b", "d");
    add_edge(g, "c", "d");
    add_edge(g, "d", "e");
    add_edge(g, "a", "d");
    assert ancestors(g, "a") == ["b", "c", "d", "e"];
    assert len(find_cycle(g)) == 0;
}
