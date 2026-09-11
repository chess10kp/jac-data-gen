"""dotnet/runtime#132559 — Mono AOT generic parent chains and build-target dependency closure."""

node GenericType {
    has name: str;
}

edge ExtendsBase: GenericType --> GenericType {}

node BuildStep {
    has name: str;
}

edge Requires: BuildStep --> BuildStep {}

walker BaseWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with GenericType entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin { self.found.append(here.name); }
        visit [->:ExtendsBase:->][?:GenericType];
    }
}

walker GenericCycleWalk {
    has state: dict[str, int] = {};
    has cycle_nodes: dict[str, bool] = {};
    has parents: dict[str, str] = {};

    can step with GenericType entry {
        if self.state.get(here.name, 0) == 2 { skip; }
        self.state[here.name] = 1;
        pars = [here ->:ExtendsBase:->][?:GenericType];
        for par in pars {
            st = self.state.get(par.name, 0);
            if st == 1 {
                self.cycle_nodes[par.name] = True;
                cur = here.name;
                while cur != par.name {
                    self.cycle_nodes[cur] = True;
                    cur = self.parents.get(cur, "");
                    if not cur { break; }
                }
            } elif st == 0 {
                par spawn GenericCycleWalk(
                    state=self.state,
                    cycle_nodes=self.cycle_nodes,
                    parents=self.parents,
                );
            }
        }
        self.state[here.name] = 2;
    }
}

walker PrereqWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with BuildStep entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin { self.found.append(here.name); }
        visit [->:Requires:->][?:BuildStep];
    }
}

walker PrereqPathWalk {
    has target: str = "";
    has max_depth: int = 12;
    has trail: list[str] = [];
    has paths: list[list[str]] = [];

    can step with BuildStep entry {
        if here.name in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.name);
        if here.name == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        kids = [here ->:Requires:->][?:BuildStep];
        nms: list[str] = [];
        for n in kids { nms.append(n.name); }
        for nm in sorted(nms) {
            for n in kids {
                if n.name == nm {
                    n spawn PrereqPathWalk(
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

obj AotGenericGraph {
    has types: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has steps: dict[str, bool] = {};
    has deps: dict[str, list[str]] = {};
    has type_nodes: dict[str, GenericType] = {};
    has step_nodes: dict[str, BuildStep] = {};
}

def load_aot_generic_graph(
    types: list[tuple[str, str]],
    steps: list[str],
    step_deps: list[tuple[str, str]],
) -> AotGenericGraph {
    g = AotGenericGraph();
    for (name, base) in types {
        g.types[name] = True;
        g.parent[name] = base if base else "";
        tnd = GenericType(name=name);
        root ++> tnd;
        g.type_nodes[name] = tnd;
    }
    for (name, base) in types {
        if base and base in g.types {
            child = g.type_nodes.get(name, None);
            par = g.type_nodes.get(base, None);
            if child is not None and par is not None { child +>:ExtendsBase:+> par; }
        }
    }
    for step in steps {
        g.steps[step] = True;
        if step not in g.deps { g.deps[step] = []; }
        snd = BuildStep(name=step);
        root ++> snd;
        g.step_nodes[step] = snd;
    }
    for (consumer, prereq) in step_deps {
        if consumer in g.steps and prereq in g.steps {
            if consumer not in g.deps { g.deps[consumer] = []; }
            g.deps[consumer].append(prereq);
            c = g.step_nodes.get(consumer, None);
            p = g.step_nodes.get(prereq, None);
            if c is not None and p is not None { c +>:Requires:+> p; }
        }
    }
    return g;
}

def transitive_bases(g: AotGenericGraph, type_name: str) -> list[str] {
    if type_name not in g.types { return []; }
    nd = g.type_nodes.get(type_name, None);
    if nd is None { return []; }
    w = nd spawn BaseWalk(claimed={}, found=[], origin=type_name);
    return sorted(w.found);
}

def recursive_generic_types(g: AotGenericGraph) -> list[str] {
    st: dict[str, int] = {};
    tnames: list[str] = [];
    for tn in g.types { tnames.append(tn); }
    for tn in tnames { st[tn] = 0; }
    cy: dict[str, bool] = {};
    for nm in sorted(tnames) {
        if st.get(nm, 0) != 0 { continue; }
        nd = g.type_nodes.get(nm, None);
        if nd is None { continue; }
        nd spawn GenericCycleWalk(state=st, cycle_nodes=cy, parents=g.parent);
    }
    out: list[str] = [];
    for cn in cy { out.append(cn); }
    return sorted(out);
}

def transitive_build_prereqs(g: AotGenericGraph, step: str) -> list[str] {
    if step not in g.steps { return []; }
    nd = g.step_nodes.get(step, None);
    if nd is None { return []; }
    w = nd spawn PrereqWalk(claimed={}, found=[], origin=step);
    return sorted(w.found);
}

def build_prereq_paths(
    g: AotGenericGraph,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    if source not in g.steps or target not in g.steps { return []; }
    nd = g.step_nodes.get(source, None);
    if nd is None { return []; }
    w = nd spawn PrereqPathWalk(
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

test "diamond revisit transitive prereqs" {
    g = load_aot_generic_graph(
        [],
        ["root", "left", "right", "join"],
        [
            ("root", "left"),
            ("root", "right"),
            ("left", "join"),
            ("right", "join"),
        ],
    );
    assert transitive_build_prereqs(g, "root") == ["join", "left", "right"];
    assert transitive_build_prereqs(g, "join") == [];
}

test "unknown id and filtered step edge tolerance" {
    g = load_aot_generic_graph(
        [("Only", "")],
        ["solo"],
        [("solo", "ghost"), ("ghost", "solo"), ("extra", "solo")],
    );
    assert transitive_bases(g, "missing") == [];
    assert recursive_generic_types(g) == [];
    assert transitive_build_prereqs(g, "missing") == [];
    assert build_prereq_paths(g, "solo", "ghost") == [];
    assert build_prereq_paths(g, "ghost", "solo") == [];
    assert transitive_build_prereqs(g, "solo") == [];
}

test "transitive bases chain external and cyclic parents" {
    g = load_aot_generic_graph(
        [
            ("Child", "Parent"),
            ("Parent", "Grand"),
            ("LoopA", "LoopB"),
            ("LoopB", "LoopC"),
            ("LoopC", "LoopA"),
            ("Orphan", "Outside"),
        ],
        [],
        [],
    );
    assert transitive_bases(g, "Child") == ["Grand", "Parent"];
    assert transitive_bases(g, "Orphan") == ["Outside"];
    assert transitive_bases(g, "LoopA") == ["LoopA", "LoopB", "LoopC"];
    assert transitive_bases(g, "missing") == [];
}

test "recursive generic cycle nodes" {
    g = load_aot_generic_graph(
        [
            ("Alpha", "Beta"),
            ("Beta", "Gamma"),
            ("Gamma", "Alpha"),
            ("SelfRef", "SelfRef"),
            ("Acyclic", "Root"),
            ("Root", ""),
        ],
        [],
        [],
    );
    assert recursive_generic_types(g) == ["Alpha", "Beta", "Gamma", "SelfRef"];
}

test "prereq paths diamond enumeration and direction" {
    g = load_aot_generic_graph(
        [],
        ["a", "b", "c", "d"],
        [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
    );
    assert build_prereq_paths(g, "a", "d") == [["a", "b", "d"], ["a", "c", "d"]];
    assert build_prereq_paths(g, "d", "a") == [];
}

test "prereq paths cycle depth and self target" {
    g = load_aot_generic_graph(
        [],
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert build_prereq_paths(g, "a", "a") == [["a"]];
    assert build_prereq_paths(g, "a", "c", max_depth=2) == [];
    assert build_prereq_paths(g, "a", "c", max_depth=3) == [["a", "b", "c"]];
}
