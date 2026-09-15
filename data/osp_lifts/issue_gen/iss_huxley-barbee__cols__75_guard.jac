"""huxley-barbee/cols#75 — dependency graph topological sort."""

node GraphAnchor {}

node Cell {
    has cid: str;
}

edge Depends {}
edge Member {}

walker FindCell {
    has target: str;
    has found: Cell | None = None;

    can seek_anchor with GraphAnchor entry {
        for ch in [here ->:Member:->][?:Cell] {
            visit ch;
        }
        print {"find": self.target, "hit": self.found != None};
    }

    can seek_cell with Cell entry {
        if here.cid == self.target {
            self.found = here;
            disengage;
        }
        for ch in [here ->:Member:->][?:Cell] {
            visit ch;
        }
    }
}

walker TopoWalk {
    has claimed: dict[str, bool] = {};
    has active: dict[str, bool] = {};
    has order: list[str] = [];
    has cyclic: bool = False;

    can walk_anchor with GraphAnchor entry {
        for ch in [here ->:Member:->][?:Cell] {
            visit :0: ch;
        }
        print {"topo": self.order, "cyclic": self.cyclic};
    }

    can walk_cell with Cell entry {
        if here.cid in self.claimed {
            skip;
        }
        if here.cid in self.active {
            self.cyclic = True;
            skip;
        }
        self.active[here.cid] = True;
        for dep in [here ->:Depends:->][?:Cell] {
            visit :0: dep;
        }
        self.active[here.cid] = False;
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
    }
}

obj DepGraphState {
    has anchor: GraphAnchor;

    def add_dependency(cell: str, dependency: str) -> None {
        c = ensure_cell(self.anchor, cell);
        d = ensure_cell(self.anchor, dependency);
        c +>:Depends:+> d;
    }

    def remove_cell(cell: str) -> None {
        w = self.anchor spawn FindCell(target=cell);
        if w.found == None {
            return;
        }
        purge_cell(self.anchor, w.found);
    }

    def topo_sort -> list[str] {
        w = self.anchor spawn TopoWalk;
        if w.cyclic {
            empty: list[str] = [];
            return empty;
        }
        return w.order;
    }

    def has_cycle -> bool {
        w = self.anchor spawn TopoWalk;
        return w.cyclic;
    }
}

def DepGraph -> DepGraphState {
    anc = GraphAnchor();
    root ++> anc;
    return DepGraphState(anchor=anc);
}

def ensure_cell(anchor: GraphAnchor, cid: str) -> Cell {
    w = anchor spawn FindCell(target=cid);
    if w.found != None {
        return w.found;
    }
    nd = Cell(cid=cid);
    anchor +>:Member:+> nd;
    return nd;
}

def purge_cell(anchor: GraphAnchor, target: Cell) {
    outs: list[Cell] = [];
    for dep in [target ->:Depends:->][?:Cell] {
        outs.append(dep);
    }
    for dep in outs {
        target -:Depends:- dep;
    }
    members: list[Cell] = [];
    for m in [anchor ->:Member:->][?:Cell] {
        members.append(m);
    }
    for parent in members {
        if parent == target {
            anchor -:Member:- parent;
        } else {
            hits: list[Cell] = [];
            for dep in [parent ->:Depends:->][?:Cell] {
                if dep == target {
                    hits.append(dep);
                }
            }
            for dep in hits {
                parent -:Depends:- dep;
            }
        }
    }
}

with entry {
    g = DepGraph();
    g.add_dependency("A", "B");
    g.add_dependency("B", "C");
    root spawn TopoWalk;
    wk = g.anchor spawn TopoWalk;
    print {"demo": wk.order};
}

"""huxley-barbee/cols#75 — dependency graph topological sort."""

node GraphAnchor {}

node Cell {
    has cid: str;
}

edge Depends {}
edge Member {}

walker FindCell {
    has target: str;
    has found: Cell | None = None;

    can seek_anchor with GraphAnchor entry {
        for ch in [here ->:Member:->][?:Cell] {
            visit ch;
        }
        print {"find": self.target, "hit": self.found != None};
    }

    can seek_cell with Cell entry {
        if here.cid == self.target {
            self.found = here;
            disengage;
        }
        for ch in [here ->:Member:->][?:Cell] {
            visit ch;
        }
    }
}

walker TopoWalk {
    has claimed: dict[str, bool] = {};
    has active: dict[str, bool] = {};
    has order: list[str] = [];
    has cyclic: bool = False;

    can walk_anchor with GraphAnchor entry {
        for ch in [here ->:Member:->][?:Cell] {
            visit :0: ch;
        }
        print {"topo": self.order, "cyclic": self.cyclic};
    }

    can walk_cell with Cell entry {
        if here.cid in self.claimed {
            skip;
        }
        if here.cid in self.active {
            self.cyclic = True;
            skip;
        }
        self.active[here.cid] = True;
        for dep in [here ->:Depends:->][?:Cell] {
            visit :0: dep;
        }
        self.active[here.cid] = False;
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
    }
}

obj DepGraphState {
    has anchor: GraphAnchor;

    def add_dependency(cell: str, dependency: str) -> None {
        c = ensure_cell(self.anchor, cell);
        d = ensure_cell(self.anchor, dependency);
        c +>:Depends:+> d;
    }

    def remove_cell(cell: str) -> None {
        w = self.anchor spawn FindCell(target=cell);
        if w.found == None {
            return;
        }
        purge_cell(self.anchor, w.found);
    }

    def topo_sort -> list[str] {
        w = self.anchor spawn TopoWalk;
        if w.cyclic {
            empty: list[str] = [];
            return empty;
        }
        return w.order;
    }

    def has_cycle -> bool {
        w = self.anchor spawn TopoWalk;
        return w.cyclic;
    }
}

def DepGraph -> DepGraphState {
    anc = GraphAnchor();
    root ++> anc;
    return DepGraphState(anchor=anc);
}

def ensure_cell(anchor: GraphAnchor, cid: str) -> Cell {
    w = anchor spawn FindCell(target=cid);
    if w.found != None {
        return w.found;
    }
    nd = Cell(cid=cid);
    anchor +>:Member:+> nd;
    return nd;
}

def purge_cell(anchor: GraphAnchor, target: Cell) {
    outs: list[Cell] = [];
    for dep in [target ->:Depends:->][?:Cell] {
        outs.append(dep);
    }
    for dep in outs {
        target -:Depends:- dep;
    }
    members: list[Cell] = [];
    for m in [anchor ->:Member:->][?:Cell] {
        members.append(m);
    }
    for parent in members {
        if parent == target {
            anchor -:Member:- parent;
        } else {
            hits: list[Cell] = [];
            for dep in [parent ->:Depends:->][?:Cell] {
                if dep == target {
                    hits.append(dep);
                }
            }
            for dep in hits {
                parent -:Depends:- dep;
            }
        }
    }
}

test "linear_topo" {
    g = DepGraph();
    g.add_dependency("A", "B");
    g.add_dependency("B", "C");
    got = g.topo_sort();
    assert got == ["C", "B", "A"];
}

test "no_cycle" {
    g = DepGraph();
    g.add_dependency("A", "B");
    g.add_dependency("B", "C");
    assert g.has_cycle() == False;
}

test "detects_cycle" {
    g = DepGraph();
    g.add_dependency("A", "B");
    g.add_dependency("B", "A");
    assert g.has_cycle() == True;
}

test "cycle_empty_topo" {
    g = DepGraph();
    g.add_dependency("A", "B");
    g.add_dependency("B", "A");
    got = g.topo_sort();
    empty: list[str] = [];
    assert got == empty;
}

test "remove_cell" {
    g = DepGraph();
    g.add_dependency("A", "B");
    g.remove_cell("A");
    got = g.topo_sort();
    assert got == ["B"];
}

test "remove_unknown_noop" {
    g = DepGraph();
    g.add_dependency("A", "B");
    g.remove_cell("Z");
    got = g.topo_sort();
    assert got == ["B", "A"];
}
