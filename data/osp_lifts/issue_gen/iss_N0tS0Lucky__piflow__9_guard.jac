"""Hand-rolled invoke workflow resolver with cycle detection.

Synthetic before-code for N0tS0Lucky/piflow#9 (definition-format invoke cycles).
"""

glob _ALLOWED_INVOKE_KEYS = {"id", "type", "workflow"};

class DefinitionError(Exception) {}

node Workflow {
    has name: str;
}

edge Invokes {}

walker InvokeCycleFind {
    has trail: list[str] = [];
    has hit: list[str] | None = None;

    can step with Workflow entry {
        if self.hit is not None { skip; }
        cycle_at = -1;
        for (i, n) in enumerate(self.trail) {
            if n == here.name { cycle_at = i; }
        }
        if cycle_at >= 0 {
            tail: list[str] = [];
            for j in range(cycle_at, len(self.trail)) {
                tail.append(self.trail[j]);
            }
            tail.append(here.name);
            self.hit = tail;
            skip;
        }
        new_trail: list[str] = [];
        for t in self.trail { new_trail.append(t); }
        new_trail.append(here.name);
        nbrs = [here ->:Invokes:->][?:Workflow];
        names: list[str] = [];
        for n in nbrs { names.append(n.name); }
        for nm in sorted(names) {
            for n in nbrs {
                if n.name == nm {
                    child = n spawn InvokeCycleFind(trail=new_trail, hit=None);
                    if child.hit is not None {
                        self.hit = child.hit;
                        skip;
                    }
                }
            }
        }
    }
}

walker InvokeDepResolve {
    has workflows: dict[str, dict];
    has resolved: dict[str, dict];
    has source_file: str;
    has claimed: dict[str, bool] = {};

    can step with Workflow entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        nbrs = [here ->:Invokes:->][?:Workflow];
        names: list[str] = [];
        for n in nbrs { names.append(n.name); }
        for nm in sorted(names) {
            for n in nbrs {
                if n.name == nm { visit :0: [n]; }
            }
        }
    }

    can finish with Workflow exit {
        if here.name in self.resolved { skip; }
        wf = self.workflows[here.name];
        body = dict(wf);
        body["steps"] = _resolve_steps(
            wf.get("steps", []) as list, self.workflows, self.resolved, self.source_file
        );
        self.resolved[here.name] = body;
    }
}

def _load_invoke_graph(workflows: dict[str, dict]) -> dict[str, Workflow] {
    nodes: dict[str, Workflow] = {};
    for name in workflows {
        nd = Workflow(name=name);
        root ++> nd;
        nodes[name] = nd;
    }
    for name in sorted(workflows) {
        src = nodes[name];
        targets = sorted(_collect_invoke_targets(workflows[name].get("steps", []) as list));
        seen: dict[str, bool] = {};
        for tgt in targets {
            if tgt not in seen {
                seen[tgt] = True;
                dst = nodes.get(tgt, None);
                if dst is not None { src +>:Invokes:+> dst; }
            }
        }
    }
    return nodes;
}

def _nodes_from_adj(adj: dict[str, list[str]]) -> dict[str, Workflow] {
    nodes: dict[str, Workflow] = {};
    for name in adj {
        nd = Workflow(name=name);
        root ++> nd;
        nodes[name] = nd;
    }
    for name in sorted(adj) {
        src = nodes[name];
        for tgt in adj[name] {
            dst = nodes.get(tgt, None);
            if dst is not None { src +>:Invokes:+> dst; }
        }
    }
    return nodes;
}

def validate_invoke_step(step: dict) -> None {
    unknown: list[str] = [];
    for k in step.keys() {
        if k not in _ALLOWED_INVOKE_KEYS { unknown.append(k); }
    }
    if len(unknown) > 0 {
        raise DefinitionError(f"unknown invoke keys: {sorted(unknown)}");
    }
    if "workflow" not in step {
        raise DefinitionError("invoke step missing required workflow");
    }
}

def _collect_invoke_targets(steps: list) -> list[str] {
    out: list[str] = [];
    pending: list = [];
    for s in steps { pending.append(s); }
    idx = 0;
    while idx < len(pending) {
        step = pending[idx];
        idx += 1;
        stype = step.get("type", None);
        if stype == "invoke" {
            out.append(step["workflow"] as str);
        } elif stype == "parallel" {
            for child in step.get("steps", []) as list {
                pending.append(child);
            }
        }
    }
    return out;
}

def build_invoke_adjacency(workflows: dict[str, dict]) -> dict[str, list[str]] {
    adj: dict[str, list[str]] = {};
    for name in workflows { adj[name] = []; }
    for name in sorted(workflows) {
        targets = sorted(_collect_invoke_targets(workflows[name].get("steps", []) as list));
        seen: dict[str, bool] = {};
        row: list[str] = [];
        for tgt in targets {
            if tgt not in seen {
                seen[tgt] = True;
                row.append(tgt);
            }
        }
        adj[name] = row;
    }
    return adj;
}

def find_cycle_path(adj: dict[str, list[str]], start: str) -> list[str] | None {
    if start not in adj { return None; }
    nodes = _nodes_from_adj(adj);
    nd = nodes.get(start, None);
    if nd is None { return None; }
    w = nd spawn InvokeCycleFind(trail=[], hit=None);
    return w.hit;
}

def detect_invoke_cycles(adj: dict[str, list[str]]) -> list[str] | None {
    roots: list[str] = [];
    for k in adj { roots.append(k); }
    for root_name in sorted(roots) {
        cycle = find_cycle_path(adj, root_name);
        if cycle is not None { return cycle; }
    }
    return None;
}

def _resolve_steps(
    steps: list,
    workflows: dict[str, dict],
    resolved: dict[str, dict],
    source_file: str,
) -> list {
    out: list = [];
    for step in steps {
        stype = step.get("type", None);
        if stype == "invoke" {
            validate_invoke_step(step);
            target = step["workflow"] as str;
            if target not in workflows {
                sid = step.get("id", "<unknown>");
                raise DefinitionError(
                    f"missing workflow '{target}' for step '{sid}' in {source_file}"
                );
            }
            if target not in resolved {
                resolved[target] = _resolve_workflow(
                    target, workflows, resolved, source_file
                );
            }
            row = dict(step);
            row["resolved_workflow"] = resolved[target];
            out.append(row);
        } elif stype == "parallel" {
            row = dict(step);
            row["steps"] = _resolve_steps(
                step.get("steps", []) as list, workflows, resolved, source_file
            );
            out.append(row);
        } else {
            out.append(dict(step));
        }
    }
    return out;
}

def _resolve_workflow(
    name: str,
    workflows: dict[str, dict],
    resolved: dict[str, dict],
    source_file: str,
) -> dict {
    if name in resolved { return resolved[name]; }
    nodes = _load_invoke_graph(workflows);
    nd = nodes[name];
    nd spawn InvokeDepResolve(
        workflows=workflows,
        resolved=resolved,
        source_file=source_file,
        claimed={},
    );
    return resolved[name];
}

def resolve_workflows(
    workflows: dict[str, dict],
    source_file: str = "workflows.yaml",
) -> dict[str, dict] {
    adj = build_invoke_adjacency(workflows);
    cycle = detect_invoke_cycles(adj);
    if cycle is not None {
        raise DefinitionError(
            f"invoke cycle in {source_file}: {' -> '.join(cycle)}"
        );
    }
    resolved: dict[str, dict] = {};
    for name in sorted(workflows) {
        resolved[name] = _resolve_workflow(name, workflows, resolved, source_file);
    }
    return resolved;
}

test "invoke diamond revisit resolves shared leaf" {
    workflows = {
        "hub": {"steps": [
            {"type": "invoke", "id": "l", "workflow": "left"},
            {"type": "invoke", "id": "r", "workflow": "right"},
        ]},
        "left": {"steps": [{"type": "invoke", "id": "j", "workflow": "leaf"}]},
        "right": {"steps": [{"type": "invoke", "id": "j2", "workflow": "leaf"}]},
        "leaf": {"steps": [{"type": "shell", "id": "s"}]},
    };
    adj = build_invoke_adjacency(workflows);
    assert adj == {"hub": ["left", "right"], "left": ["leaf"], "right": ["leaf"], "leaf": []};;
    assert detect_invoke_cycles(adj) is None;;
    resolved = resolve_workflows(workflows);
    assert resolved["hub"]["steps"][0]["resolved_workflow"]["steps"][0]["resolved_workflow"]["steps"] == [{"type": "shell", "id": "s"}];;
    assert resolved["hub"]["steps"][1]["resolved_workflow"]["steps"][0]["resolved_workflow"]["steps"] == [{"type": "shell", "id": "s"}];;
}

test "unknown id tolerance across cycle layer and resolve" {
    adj = {"only": []};
    assert find_cycle_path(adj, "ghost") is None;;
    assert detect_invoke_cycles(adj) is None;;
    adj_dangling = {"a": ["ghost"]};
    assert find_cycle_path(adj_dangling, "a") is None;;
    workflows = {"solo": {"steps": [{"type": "invoke", "id": "x", "workflow": "missing"}]}};
    assert build_invoke_adjacency(workflows) == {"solo": ["missing"]};;
    try {
        resolve_workflows(workflows);
        assert False, "should raise DefinitionError";
    } except DefinitionError as e {
        assert "missing workflow 'missing' for step 'x' in workflows.yaml" in str(e);;
    }
}

test "find_cycle_path diamond revisit returns no cycle" {
    adj = {
        "hub": ["left", "right"],
        "left": ["leaf"],
        "right": ["leaf"],
        "leaf": [],
    };
    assert find_cycle_path(adj, "hub") is None;;
    assert detect_invoke_cycles(adj) is None;;
}

test "invoke cycle detection self loop and sorted roots" {
    w_self = {"loop": {"steps": [{"type": "invoke", "id": "self", "workflow": "loop"}]}};
    assert detect_invoke_cycles(build_invoke_adjacency(w_self)) == ["loop", "loop"];;
    w_multi = {
        "alpha": {"steps": []},
        "beta": {"steps": [{"type": "invoke", "id": "1", "workflow": "gamma"}]},
        "gamma": {"steps": [{"type": "invoke", "id": "2", "workflow": "beta"}]},
    };
    assert detect_invoke_cycles(build_invoke_adjacency(w_multi)) == ["beta", "gamma", "beta"];;
    try {
        resolve_workflows(w_self, source_file="defs.yaml");
        assert False, "should raise DefinitionError";
    } except DefinitionError as e {
        assert str(e) == "invoke cycle in defs.yaml: loop -> loop";;
    }
}

test "parallel nested duplicate invoke targets deduped" {
    workflows = {
        "main": {"steps": [{"type": "parallel", "id": "p", "steps": [
            {"type": "invoke", "id": "a", "workflow": "sub"},
            {"type": "invoke", "id": "b", "workflow": "sub"},
        ]}]},
        "sub": {"steps": [{"type": "shell", "id": "run"}]},
    };
    assert build_invoke_adjacency(workflows) == {"main": ["sub"], "sub": []};;
    resolved = resolve_workflows(workflows);
    assert resolved["main"]["steps"][0]["steps"][0]["resolved_workflow"]["steps"] == [{"type": "shell", "id": "run"}];;
}

test "validate invoke step rejects malformed invoke rows" {
    try {
        validate_invoke_step({"type": "invoke", "id": "x", "extra": 1});
        assert False, "should raise DefinitionError";
    } except DefinitionError as e {
        assert str(e) == "unknown invoke keys: ['extra']";;
    }
    try {
        validate_invoke_step({"type": "invoke", "id": "x"});
        assert False, "should raise DefinitionError";
    } except DefinitionError as e {
        assert str(e) == "invoke step missing required workflow";;
    }
}
