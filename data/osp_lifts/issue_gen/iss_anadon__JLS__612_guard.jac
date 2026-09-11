"""anadon/JLS#612 — confined .dig import workflow DAG and path reachability."""

node Section {
    has section_id: str;
}

edge Depends {}

walker TransitiveDepsWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Section entry {
        if here.section_id in self.claimed { skip; }
        self.claimed[here.section_id] = True;
        if here.section_id != self.origin {
            self.found.append(here.section_id);
        }
        visit [->:Depends:->][?:Section];
    }
}

walker DownstreamTasksWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Section entry {
        if here.section_id in self.claimed { skip; }
        self.claimed[here.section_id] = True;
        if here.section_id != self.origin {
            self.found.append(here.section_id);
        }
        visit [<-:Depends:<-][?:Section];
    }
}

walker DepPathWalk {
    has target: str = "";
    has max_depth: int = 12;
    has trail: list[str] = [];
    has paths: list[list[str]] = [];

    can step with Section entry {
        if here.section_id in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.section_id);
        if here.section_id == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        kids = [here ->:Depends:->][?:Section];
        nms: list[str] = [];
        for n in kids { nms.append(n.section_id); }
        for nm in sorted(nms) {
            for n in kids {
                if n.section_id == nm {
                    n spawn DepPathWalk(
                        target=self.target,
                        max_depth=self.max_depth,
                        trail=nt,
                        paths=self.paths,
                    );
                }
            }
        }
    }
}

obj DigWorkflow {
    has sections: dict[str, list[str]] = {};
    has nodes: dict[str, Section] = {};

    def add_section(section_id: str, test_vectors: list[str] | None = None) -> None {
        if section_id not in self.sections {
            self.sections[section_id] = [];
        }
        if test_vectors {
            for v in test_vectors {
                self.sections[section_id].append(v);
            }
        }
        if section_id not in self.nodes {
            nd = Section(section_id=section_id);
            root ++> nd;
            self.nodes[section_id] = nd;
        }
    }

    def add_dependency(consumer: str, depends_on: str) -> None {
        if consumer in self.sections and depends_on in self.sections {
            c = self.nodes.get(consumer, None);
            d = self.nodes.get(depends_on, None);
            if c is not None and d is not None { c +>:Depends:+> d; }
        }
    }
}

def load_dig_workflow(
    sections: list[tuple[str, list[str]]],
    edges: list[tuple[str, str]],
) -> DigWorkflow {
    graph = DigWorkflow();
    for (section_id, vectors) in sections {
        graph.add_section(section_id, vectors);
    }
    for (consumer, depends_on) in edges {
        graph.add_dependency(consumer, depends_on);
    }
    return graph;
}

def transitive_dependencies(graph: DigWorkflow, `root: str) -> list[str] {
    if `root not in graph.sections { return []; }
    nd = graph.nodes.get(`root, None);
    if nd is None { return []; }
    w = nd spawn TransitiveDepsWalk(claimed={}, found=[], origin=`root);
    return sorted(w.found);
}

def dependency_paths(
    graph: DigWorkflow,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    if source not in graph.sections or target not in graph.sections { return []; }
    nd = graph.nodes.get(source, None);
    if nd is None { return []; }
    w = nd spawn DepPathWalk(
        target=target,
        max_depth=max_depth,
        trail=[],
        paths=[],
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def preserved_test_vectors(graph: DigWorkflow, section_id: str) -> list[str] {
    if section_id not in graph.sections { return []; }
    out: list[str] = [];
    for v in graph.sections[section_id] { out.append(v); }
    return sorted(out);
}

def downstream_tasks(graph: DigWorkflow, `root: str) -> list[str] {
    if `root not in graph.sections { return []; }
    nd = graph.nodes.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DownstreamTasksWalk(claimed={}, found=[], origin=`root);
    return sorted(w.found);
}

test "diamond revisit transitive closure" {
    g = load_dig_workflow(
        [("root", []), ("left", []), ("right", []), ("join", [])],
        [("root", "left"), ("root", "right"), ("left", "join"), ("right", "join")],
    );
    assert transitive_dependencies(g, "root") == ["join", "left", "right"];
    assert transitive_dependencies(g, "join") == [];
}

test "downstream diamond fanout" {
    g = load_dig_workflow(
        [("hub", []), ("mid_a", []), ("mid_b", []), ("leaf", [])],
        [("leaf", "hub"), ("mid_a", "leaf"), ("mid_b", "leaf")],
    );
    assert downstream_tasks(g, "hub") == ["leaf", "mid_a", "mid_b"];
    assert downstream_tasks(g, "mid_a") == [];
}

test "unknown id tolerance" {
    g = load_dig_workflow([("only", [])], []);
    assert transitive_dependencies(g, "missing") == [];
    assert downstream_tasks(g, "missing") == [];
    assert dependency_paths(g, "only", "ghost") == [];
    assert dependency_paths(g, "ghost", "only") == [];
    assert preserved_test_vectors(g, "ghost") == [];
    g.add_dependency("only", "ghost");
    g.add_dependency("ghost", "only");
    assert transitive_dependencies(g, "only") == [];
}

test "dependency paths cycle depth and self" {
    g = load_dig_workflow(
        [("a", []), ("b", []), ("c", [])],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert dependency_paths(g, "a", "a") == [["a"]];
    assert dependency_paths(g, "a", "c", max_depth=2) == [];
    assert dependency_paths(g, "a", "c", max_depth=3) == [["a", "b", "c"]];
}

test "dependency paths diamond enumeration" {
    g = load_dig_workflow(
        [("a", []), ("b", []), ("c", []), ("d", [])],
        [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
    );
    assert dependency_paths(g, "a", "d") == [["a", "b", "d"], ["a", "c", "d"]];
    assert dependency_paths(g, "d", "a") == [];
}

test "preserved test vectors ordering and empty section" {
    g = load_dig_workflow(
        [("alpha", ["z", "a", "m"]), ("beta", []), ("gamma", ["solo"])],
        [],
    );
    assert preserved_test_vectors(g, "alpha") == ["a", "m", "z"];
    assert preserved_test_vectors(g, "beta") == [];
    assert preserved_test_vectors(g, "gamma") == ["solo"];
    assert preserved_test_vectors(g, "nope") == [];
}
