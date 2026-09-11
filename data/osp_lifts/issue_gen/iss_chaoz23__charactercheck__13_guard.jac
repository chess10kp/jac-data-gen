"""Guard: chaoz23/charactercheck#13."""

obj InputStore { has children: dict[str, list[str]] = {}; has max_depth: int = 32; }
node Container { has cid: str; }
edge Child {}

walker CycleWalk {
    has claimed: dict[str, bool] = {};
    has has_cycle: bool = False;
    can step with Container entry {
        if here.cid in self.claimed { self.has_cycle = True; skip; }
        self.claimed[here.cid] = True;
        visit [->:Child:->] else { disengage; };
    }
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has depth: int = 0;
    has max_depth: int = 32;
    can step with Container entry {
        if here.cid in self.claimed { skip; }
        if self.depth > self.max_depth { skip; }
        self.claimed[here.cid] = True;
        self.reached.append(here.cid);
        self.depth += 1;
        visit [->:Child:->] else { disengage; };
    }
}

walker DepthProbe {
    has claimed: dict[str, bool] = {};
    has depth: int = 0;
    has max_depth: int = 32;
    has exceeded: bool = False;
    can step with Container entry {
        if here.cid in self.claimed { skip; }
        if self.depth > self.max_depth { self.exceeded = True; skip; }
        self.claimed[here.cid] = True;
        self.depth += 1;
        visit [->:Child:->] else { disengage; };
    }
}

def _find(cid: str) -> Container | None {
    for n in [-->][?:Container] { if n.cid == cid { return n; } }
    return None;
}

def _known_ids(children: dict[str, list[str]]) -> set[str] {
    ids: set[str] = set();
    for (p, kids) in children.items() { ids.add(p); for k in kids { ids.add(k); } }
    return ids;
}

def load_containers(children: dict[str, list[str]], max_depth: int = 32) -> InputStore {
    mp: dict[str, Container] = {};
    for cid in _known_ids(children) { fresh = Container(cid=cid); root ++> fresh; mp[cid] = fresh; }
    for (p, kids) in children.items() {
        parent = mp.get(p, None);
        if parent is None { continue; }
        for k in kids {
            child = mp.get(k, None);
            if child is not None { parent +>:Child():+> child; }
        }
    }
    return InputStore(children=children, max_depth=max_depth);
}

def detect_cycles(g: InputStore, root_id: str) -> bool {
    if root_id not in _known_ids(g.children) { return False; }
    anchor = _find(root_id);
    if anchor is None { return False; }
    w = anchor spawn CycleWalk(claimed={}, has_cycle=False);
    return w.has_cycle;
}

def bounded_walk(g: InputStore, root_id: str) -> list[str] {
    if root_id not in _known_ids(g.children) { return []; }
    anchor = _find(root_id);
    if anchor is None { return []; }
    w = anchor spawn ReachWalk(claimed={}, reached=[], depth=0, max_depth=g.max_depth);
    return sorted(w.reached);
}

def validate_input(g: InputStore, root_id: str) -> str | None {
    if root_id == "" { return "invalid_path"; }
    if root_id not in _known_ids(g.children) { return "invalid_path"; }
    anchor = _find(root_id);
    if anchor is None { return "invalid_path"; }
    if detect_cycles(g, root_id) { return "cycle_detected"; }
    w = anchor spawn DepthProbe(claimed={}, depth=0, max_depth=g.max_depth, exceeded=False);
    if w.exceeded { return "depth_exceeded"; }
    return None;
}

test "empty path is invalid" {
    g = load_containers({"form": ["field42"], "field42": []});
    assert validate_input(g, "") == "invalid_path";
}

test "digit-bearing missing path is invalid" {
    g = load_containers({"form": ["field42"], "field42": []});
    assert validate_input(g, "form/99/missing") == "invalid_path";
}

test "cycle detected on self-loop chain" {
    g = load_containers({"a": ["b"], "b": ["c"], "c": ["a"]});
    assert detect_cycles(g, "a");
    assert validate_input(g, "a") == "cycle_detected";
}

test "depth overflow returns stable code" {
    g = load_containers({"a": ["b"], "b": ["c"], "c": ["d"], "d": []}, max_depth=2);
    assert validate_input(g, "a") == "depth_exceeded";
    assert bounded_walk(g, "a") == ["a", "b", "c"];
}

test "diamond adversarial revisit order" {
    g = load_containers(
        {"hub": ["left", "right"], "left": ["cap"], "right": ["cap"], "cap": []},
    );
    assert bounded_walk(g, "hub") == ["cap", "hub", "left", "right"];
    assert not detect_cycles(g, "hub");
}

test "child-only root validates" {
    g = load_containers({"parent": ["child"]});
    assert validate_input(g, "child") is None;
}
