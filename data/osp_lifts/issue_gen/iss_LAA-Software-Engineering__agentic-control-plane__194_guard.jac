"""LAA-Software-Engineering/agentic-control-plane#194 — Subworkflow invocation graph."""

node Workflow {
    has name: str;
}

edge Invokes {}

obj WorkflowStore {
    has workflows: dict[str, Workflow] = {};
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];

    can step with Workflow entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.reached.append(here.name);
        visit [->:Invokes:->][?:Workflow];
    }
}

walker CycleProbe {
    has visited: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has errors: list[tuple[str, str]] = [];

    can step with Workflow entry {
        if here.name in self.visited { skip; }
        self.visited[here.name] = True;
        self.stack[here.name] = True;
        for nxt in [here ->:Invokes:->][?:Workflow] {
            if nxt.name in self.stack {
                self.errors.append((here.name, nxt.name));
            } else {
                if not (nxt.name in self.visited) {
                    visit [nxt];
                }
            }
        }
        self.stack[here.name] = False;
    }
}

def load_workflows(
    names: list[str],
    invokes_edges: list[tuple[str, str]],
) -> WorkflowStore {
    ws = WorkflowStore();
    for name in names {
        nd = Workflow(name=name);
        root ++> nd;
        ws.workflows[name] = nd;
    }
    for (caller, callee) in invokes_edges {
        c = ws.workflows.get(caller, None);
        d = ws.workflows.get(callee, None);
        if c is not None and d is not None { c +>:Invokes:+> d; }
    }
    return ws;
}

def reachable_subworkflows(store: WorkflowStore, workflow: str) -> list[str] {
    nd = store.workflows.get(workflow, None);
    if nd is None { return []; }
    w = nd spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}

def validate_no_recursion(store: WorkflowStore) -> list[tuple[str, str]] {
    errors: list[tuple[str, str]] = [];
    visited: dict[str, bool] = {};
    for k in sorted(store.workflows.keys()) {
        if k in visited { continue; }
        nd = store.workflows[k];
        w = nd spawn CycleProbe(visited=visited, stack={}, errors=[]);
        errors = errors + w.errors;
        visited = w.visited;
    }
    return sorted(errors);
}

def max_invoke_depth(store: WorkflowStore, workflow: str, limit: int) -> bool {
    nd = store.workflows.get(workflow, None);
    if nd is None { return False; }
    depth: dict[str, int] = {workflow: 0};
    frontier: list[Workflow] = [nd];
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        cur_depth = depth[cur.name];
        for nxt in [cur ->:Invokes:->][?:Workflow] {
            next_depth = cur_depth + 1;
            if next_depth > limit { return False; }
            if not (nxt.name in depth) or next_depth > depth[nxt.name] {
                depth[nxt.name] = next_depth;
                frontier.append(nxt);
            }
        }
    }
    return True;
}

test "subworkflow reachability" {
    ws = load_workflows(
        ["main", "sub_a", "sub_b", "leaf"],
        [("main", "sub_a"), ("sub_a", "sub_b"), ("main", "leaf")],
    );
    assert reachable_subworkflows(ws, "main") == ["leaf", "main", "sub_a", "sub_b"];
    assert validate_no_recursion(ws) == [];
    assert max_invoke_depth(ws, "main", 3);
}

test "recursion detected" {
    ws = load_workflows(["a", "b"], [("a", "b"), ("b", "a")]);
    assert validate_no_recursion(ws) == [("b", "a")];
}

test "diamond adversarial revisit" {
    ws = load_workflows(
        ["hub", "left", "right", "bot"],
        [("right", "bot"), ("hub", "left"), ("left", "bot"), ("hub", "right")],
    );
    assert reachable_subworkflows(ws, "hub") == ["bot", "hub", "left", "right"];
    assert reachable_subworkflows(ws, "missing") == [];
}
