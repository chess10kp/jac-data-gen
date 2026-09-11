"""Probabilistic-composer column DAG ancestry queries.

probcomp/bdbcontrib#73 lifted to OSP: generator columns become Column
archetypes and parent links become typed DependsOn edges with a mirrored
DependentOf edge so child queries stay walker-native. The recursive descent
over the adjacency list becomes flooding walkers whose seen map is the cycle
policy, and the Markov blanket is assembled from per-node one-hop probes --
all results are plain sets of column names.
"""
node Column {
    has name: str;
}
edge DependsOn {}
edge DependentOf {}

"""Composer handle: column names resolve through this lookup map."""
obj Composer {
    has cols: dict[str, Column];

    def resolve(name: str) -> Column | None {
        return self.cols.get(name);
    }
}

walker ParentHop {
    has outs: list[str] = [];
    has started: bool = False;

    can step with Column entry {
        if not self.started {
            self.started = True;
            visit [->:DependsOn:->];
        } else {
            if here.name not in self.outs {
                self.outs.append(here.name);
            }
        }
    }
}

walker ChildHop {
    has outs: list[str] = [];
    has started: bool = False;

    can step with Column entry {
        if not self.started {
            self.started = True;
            visit [->:DependentOf:->];
        } else {
            if here.name not in self.outs {
                self.outs.append(here.name);
            }
        }
    }
}

walker AncestorFlood {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_name: str = "";

    can step with Column entry {
        if here.name in self.claimed {
            skip;
        }
        if here.name != self.start_name {
            self.reached.append(here.name);
        }
        self.claimed[here.name] = True;
        visit [->:DependsOn:->];
    }
}

walker DescendantFlood {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has start_name: str = "";

    can step with Column entry {
        if here.name in self.claimed {
            skip;
        }
        if here.name != self.start_name {
            self.reached.append(here.name);
        }
        self.claimed[here.name] = True;
        visit [->:DependentOf:->];
    }
}

walker DependenceProbe {
    has target: str = "";
    has found: bool = False;
    has claimed: dict[str, bool] = {};
    has started: bool = False;

    can step with Column entry {
        if not self.started {
            self.started = True;
            self.claimed[here.name] = True;
            visit [->:DependsOn:->];
        } else {
            if here.name == self.target {
                self.found = True;
                disengage;
            }
            if here.name in self.claimed {
                skip;
            }
            self.claimed[here.name] = True;
            visit [->:DependsOn:->];
        }
    }
}

def _parents_of(g: Composer, name: str) -> list[str] {
    c = g.resolve(name);
    if c is None {
        return [];
    }
    w = c spawn ParentHop();
    return w.outs;
}

def _children_of(g: Composer, name: str) -> list[str] {
    c = g.resolve(name);
    if c is None {
        return [];
    }
    w = c spawn ChildHop();
    return w.outs;
}

def create_generator(g: Composer, name: str, parents: list[str] = []) -> None {
    for p in parents {
        if g.resolve(p) is None {
            raise KeyError(p);
        }
    }
    c = Column(name=name);
    root ++> c;
    g.cols[name] = c;
    for p in parents {
        pc = g.resolve(p);
        if pc is None {
            continue;
        }
        c +>:DependsOn:+> pc;
        pc +>:DependentOf:+> c;
    }
}

"""All transitive parents of ``name`` (sorted set); unknown yields []."""
def ancestors(g: Composer, name: str) -> list[str] {
    c = g.resolve(name);
    if c is None {
        return [];
    }
    w = c spawn AncestorFlood(start_name=name);
    return sorted(w.reached);
}

"""All transitive children of ``name`` (sorted set); unknown yields []."""
def descendants(g: Composer, name: str) -> list[str] {
    c = g.resolve(name);
    if c is None {
        return [];
    }
    w = c spawn DescendantFlood(start_name=name);
    return sorted(w.reached);
}

"""True when ``descendant`` transitively depends on ``ancestor``."""
def depends_on(g: Composer, ancestor: str, descendant: str) -> bool {
    d = g.resolve(descendant);
    if d is None {
        return False;
    }
    w = d spawn DependenceProbe(target=ancestor);
    return w.found;
}

"""Parents + children + co-parents of ``name`` (sorted set, minus itself)."""
def markov_blanket(g: Composer, name: str) -> list[str] {
    if g.resolve(name) is None {
        return [];
    }
    claim: dict[str, bool] = {};
    for p in _parents_of(g, name) + _children_of(g, name) {
        claim[p] = True;
    }
    for child in _children_of(g, name) {
        for cop in _parents_of(g, child) {
            claim[cop] = True;
        }
    }
    claim.pop(name, None);
    return sorted(claim.keys());
}

def _fixture() -> Composer {
    c = Composer(cols={});
    create_generator(c, "age");
    create_generator(c, "hours");
    create_generator(c, "salary", parents=["age", "hours"]);
    create_generator(c, "cluster_1", parents=["age"]);
    create_generator(c, "cluster_2", parents=["hours", "age"]);
    create_generator(c, "view", parents=["salary", "cluster_1"]);
    return c;
}

test "ancestry closures" {
    c = _fixture();
    assert ancestors(c, "view") == ["age", "cluster_1", "hours", "salary"];
    assert ancestors(c, "age") == [];
    assert descendants(c, "age") == ["cluster_1", "cluster_2", "salary", "view"];
    assert descendants(c, "view") == [];
}

test "dependence reachability" {
    c = _fixture();
    assert depends_on(c, "age", "view");
    assert depends_on(c, "hours", "view");
    assert not depends_on(c, "cluster_1", "cluster_2");
    assert not depends_on(c, "view", "age");
    assert not depends_on(c, "ghost", "age");
}

test "markov blankets" {
    c = _fixture();
    assert markov_blanket(c, "salary") == ["age", "cluster_1", "hours", "view"];
    assert markov_blanket(c, "age") == ["cluster_1", "cluster_2", "hours", "salary"];
    assert markov_blanket(c, "view") == ["cluster_1", "salary"];
    assert markov_blanket(c, "ghost") == [];
}

test "unknown parent rejected" {
    c = Composer(cols={});
    bad = False;
    try {
        create_generator(c, "x", parents=["nope"]);
    } except KeyError {
        bad = True;
    }
    assert bad;
}
