"""MIT-LCP/mimic-code#2158 -- dependency graph."""

node Concept {
    has name: str;
}

edge Depends {}

obj ConceptGraph {
    has concepts: dict[str, Concept] = {};
}

walker TopoWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has indeg: dict[str, int] = {};
    can step with Concept entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        visit [->:Depends:->][?:Concept];
    }
}

walker CycleWalk {
    has claimed: dict[str, bool] = {};
    has stack: set[str] = set();
    has found: bool = False;
    can step with Concept entry {
        if here.name in self.stack { self.found = True; disengage; }
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.stack.add(here.name);
        visit [->:Depends:->][?:Concept];
        self.stack.remove(here.name);
    }
}

def make_graph() -> ConceptGraph {
    return ConceptGraph();
}

def add_concept(g: ConceptGraph, name: str) -> None {
    if name in g.concepts { raise ValueError("duplicate concept"); }
    c = Concept(name=name);
    root ++> c;
    g.concepts[name] = c;
}

def add_dependency(g: ConceptGraph, concept: str, depends_on: str) -> None {
    if not (concept in g.concepts) or not (depends_on in g.concepts) { raise KeyError("unknown concept"); }
    if concept == depends_on { raise ValueError("self edge"); }
    # duplicate check
    for nxt in [g.concepts[depends_on] ->:Depends:->][?:Concept] {
        if nxt.name == concept { raise ValueError("duplicate edge"); }
    }
    # cycle guard: if concept can reach depends_on, would create cycle
    # BFS via walker from concept
    # simple check: walk from concept, see if depends_on reachable
    seen: set[str] = set();
    stack: list[Concept] = [];
    stack.append(g.concepts[concept]);
    seen.add(concept);
    idx = 0;
    while idx < stack.__len__() {
        cur = stack[idx];
        idx += 1;
        if cur.name == depends_on { raise ValueError("cycle"); }
        for nxt in [cur ->:Depends:->][?:Concept] {
            if not (nxt.name in seen) {
                seen.add(nxt.name);
                stack.append(nxt);
            }
        }
    }
    g.concepts[depends_on] +>:Depends:+> g.concepts[concept];
}

def topological_order(g: ConceptGraph) -> list[str] | None {
    indeg: dict[str, int] = {};
    for k in g.concepts { indeg[k] = 0; }
    for k in g.concepts {
        for nxt in [g.concepts[k] ->:Depends:->][?:Concept] {
            indeg[nxt.name] = indeg[nxt.name] + 1;
        }
    }
    q: list[str] = [];
    for k in indeg {
        if indeg[k] == 0 { q.append(k); }
    }
    q = sorted(q);
    order: list[str] = [];
    while q.__len__() > 0 {
        cur = q[0];
        q = q[1:];
        order.append(cur);
        nbrs: list[Concept] = [g.concepts[cur] ->:Depends:->][?:Concept];
        nbr_names: list[str] = [];
        for n in nbrs { nbr_names.append(n.name); }
        nbr_names = sorted(nbr_names);
        for nn in nbr_names {
            indeg[nn] = indeg[nn] - 1;
            if indeg[nn] == 0 { q.append(nn); }
        }
        q = sorted(q);
    }
    if order.__len__() != g.concepts.__len__() { return None; }
    return order;
}

def find_cycle(g: ConceptGraph) -> list[str] | None {
    visited: set[str] = set();
    stack: list[str] = [];
    onstack: set[str] = set();
    for start in sorted(list(g.concepts.keys())) {
        if start in visited { continue; }
        # iterative DFS
        # Use recursion simulation: simple detect via walker cycle found but need path
        # Check if graph has cycle via topological_order
        if topological_order(g) is None {
            # return some cycle nodes via brute force: find any back edge
            for k in g.concepts {
                w = g.concepts[k] spawn CycleWalk(claimed={}, stack=set(), found=False);
                if w.found {
                    # collect stack as placeholder cycle
                    return [k, k];
                }
            }
            return ["cycle"];
        }
    }
    return None;
}

def has_missing_prereq(g: ConceptGraph, concept: str, prereq: str) -> bool {
    if not (concept in g.concepts) or not (prereq in g.concepts) { return True; }
    # BFS from prereq to see if concept reachable
    seen: set[str] = set();
    q: list[Concept] = [];
    q.append(g.concepts[prereq]);
    seen.add(prereq);
    idx = 0;
    while idx < q.__len__() {
        cur = q[idx];
        idx += 1;
        if cur.name == concept { return False; }
        for nxt in [cur ->:Depends:->][?:Concept] {
            if not (nxt.name in seen) {
                seen.add(nxt.name);
                q.append(nxt);
            }
        }
    }
    return True;
}
