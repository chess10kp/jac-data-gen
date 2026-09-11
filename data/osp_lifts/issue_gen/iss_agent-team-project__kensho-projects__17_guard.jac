"""agent-team-project/kensho-projects#17 — Workplane M2E lifecycle and dependency DAG."""

glob LIFECYCLE = frozenset({"open", "in_progress", "in_review", "done", "cancelled"});
glob DEP_TYPES = frozenset({"blocks", "relates", "caused-by"});

class DependencyCycleError(Exception) {}

node WorkItem {
    has iid: str;
    has state: str;
    has version: int;
}

edge Blocks: WorkItem --> WorkItem {}

obj Workplane {
    has items: dict[str, dict] = {};
    has relates: dict[str, list[tuple[str, str]]] = {};
}

walker BlockerClosure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with WorkItem entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        if here.iid != self.origin { self.found.append(here.iid); }
        visit [here ->:Blocks:->][?:WorkItem];
    }
}

def _find_item(item_id: str) -> WorkItem | None {
    for nd in [root-->[?:WorkItem]] {
        if nd.iid == item_id { return nd; }
    }
    return None;
}

def _transition_allowed(cur: str, target: str) -> bool {
    if cur == "open" {
        return target == "in_progress" or target == "cancelled";
    }
    if cur == "in_progress" {
        return target == "in_review" or target == "cancelled";
    }
    if cur == "in_review" {
        return target == "in_progress" or target == "done" or target == "cancelled";
    }
    return False;
}

def load_workplane(
    items: list[tuple[str, str, int]],
    dependencies: list[tuple[str, str, str]],
) -> Workplane {
    wp = Workplane();
    for entry in items {
        iid = entry[0];
        st = entry[1];
        ver = entry[2];
        wp.items[iid] = {"state": st, "version": ver};
        nd = WorkItem(iid=iid, state=st, version=ver);
        root ++> nd;
    }
    for dep in dependencies {
        src = dep[0];
        tgt = dep[1];
        dtype = dep[2];
        if not (src in wp.items) or not (tgt in wp.items) { continue; }
        if dtype not in DEP_TYPES { continue; }
        if dtype == "blocks" {
            s = _find_item(src);
            t = _find_item(tgt);
            if s is not None and t is not None { t +>:Blocks:+> s; }
        } else {
            if not (src in wp.relates) { wp.relates[src] = []; }
            wp.relates[src].append((tgt, dtype));
            if not (tgt in wp.relates) { wp.relates[tgt] = []; }
            wp.relates[tgt].append((src, dtype));
        }
    }
    return wp;
}

def get_state(wp: Workplane, item_id: str) -> str | None {
    row = wp.items.get(item_id, None);
    if row is None { return None; }
    return str(row["state"]);
}

def blocking_closure(wp: Workplane, item_id: str) -> list[str] {
    if not (item_id in wp.items) { return []; }
    nd = _find_item(item_id);
    if nd is None { return []; }
    w = nd spawn BlockerClosure(claimed={}, found=[], origin=item_id);
    return sorted(w.found);
}

def is_blocked(wp: Workplane, item_id: str) -> bool {
    if not (item_id in wp.items) { return False; }
    for bid in blocking_closure(wp, item_id) {
        row = wp.items.get(bid, None);
        if row is not None and str(row["state"]) != "done" { return True; }
    }
    return False;
}

def would_block_cycle(wp: Workplane, blocker: str, blocked: str) -> bool {
    if blocker == blocked { return True; }
    nd = _find_item(blocker);
    if nd is None { return False; }
    w = nd spawn BlockerClosure(claimed={}, found=[], origin=blocker);
    for hit in w.found {
        if hit == blocked { return True; }
    }
    return False;
}

def add_dependency(wp: Workplane, source: str, target: str, dep_type: str) -> None {
    if dep_type not in DEP_TYPES {
        raise ValueError(f"unknown dependency type: {dep_type}");
    }
    if not (source in wp.items) or not (target in wp.items) { return; }
    if dep_type == "blocks" {
        if would_block_cycle(wp, source, target) {
            raise DependencyCycleError("dependency_cycle");
        }
        s = _find_item(source);
        t = _find_item(target);
        if s is not None and t is not None { t +>:Blocks:+> s; }
        return;
    }
    if not (source in wp.relates) { wp.relates[source] = []; }
    wp.relates[source].append((target, dep_type));
    if not (target in wp.relates) { wp.relates[target] = []; }
    wp.relates[target].append((source, dep_type));
}

def remove_dependency(wp: Workplane, source: str, target: str, dep_type: str) -> bool {
    if dep_type not in DEP_TYPES {
        raise ValueError(f"unknown dependency type: {dep_type}");
    }
    if not (source in wp.items) or not (target in wp.items) { return False; }
    if dep_type == "blocks" {
        bl_row = wp.items.get(target, None);
        if bl_row is None { return False; }
        s = _find_item(source);
        t = _find_item(target);
        if s is None or t is None { return False; }
        linked = False;
        for blk in [t ->:Blocks:->][?:WorkItem] {
            if blk.iid == source { linked = True; }
        }
        if not linked { return False; }
        t del ->:Blocks:-> s;
        return True;
    }
    pairs = wp.relates.get(source, []);
    if (target, dep_type) not in pairs { return False; }
    pairs.remove((target, dep_type));
    wp.relates[target].remove((source, dep_type));
    return True;
}

def transition(wp: Workplane, item_id: str, target: str, expected_version: int) -> int {
    row = wp.items.get(item_id, None);
    if row is None { raise KeyError(item_id); }
    if int(row["version"]) != expected_version { raise ValueError("stale_version"); }
    cur = str(row["state"]);
    if not _transition_allowed(cur, target) { raise ValueError("invalid_transition"); }
    if (target == "in_progress" or target == "done") and is_blocked(wp, item_id) {
        raise ValueError("blocked");
    }
    row["state"] = target;
    row["version"] = expected_version + 1;
    nd = _find_item(item_id);
    if nd is not None {
        nd.state = target;
        nd.version = expected_version + 1;
    }
    return int(row["version"]);
}

def related_items(wp: Workplane, item_id: str) -> list[tuple[str, str]] {
    if not (item_id in wp.items) { return []; }
    return sorted(wp.relates.get(item_id, []));
}

test "diamond blocker closure adversarial blocks insertion order" {
    wp = load_workplane(
        [
            ("top", "open", 1),
            ("mid", "open", 1),
            ("a", "done", 1),
            ("b", "done", 1),
            ("leaf", "open", 1),
        ],
        [
            ("b", "mid", "blocks"),
            ("a", "mid", "blocks"),
            ("mid", "leaf", "blocks"),
            ("top", "mid", "blocks"),
        ],
    );
    assert blocking_closure(wp, "leaf") == ["a", "b", "mid", "top"];;
    assert is_blocked(wp, "leaf") == True;;
}

test "unknown id tolerance across workplane queries" {
    wp = load_workplane([("solo", "open", 1)], []);
    assert get_state(wp, "ghost") is None;;
    assert blocking_closure(wp, "ghost") == [];;
    assert is_blocked(wp, "ghost") == False;;
    assert related_items(wp, "ghost") == [];;
    assert would_block_cycle(wp, "ghost", "solo") == False;;
    add_dependency(wp, "ghost", "solo", "relates");
    add_dependency(wp, "solo", "ghost", "blocks");
    assert related_items(wp, "solo") == [];;
    raised = False;
    try {
        transition(wp, "ghost", "in_progress", 1);
        assert False, "should have raised";
    } except KeyError {
        raised = True;
    }
    assert raised;;
}

test "cancelled transition allowed while blocked" {
    wp = load_workplane(
        [("blk", "open", 1), ("tgt", "open", 1)],
        [("blk", "tgt", "blocks")],
    );
    assert is_blocked(wp, "tgt") == True;;
    assert transition(wp, "tgt", "cancelled", 1) == 2;;
    assert get_state(wp, "tgt") == "cancelled";;
}

test "relates and caused-by never trigger dependency_cycle" {
    wp = load_workplane(
        [("x", "open", 1), ("y", "open", 1), ("z", "open", 1)],
        [("x", "y", "blocks"), ("y", "z", "blocks"), ("z", "x", "blocks")],
    );
    add_dependency(wp, "x", "y", "relates");
    add_dependency(wp, "y", "z", "caused-by");
    assert related_items(wp, "x") == [("y", "relates")];;
    assert related_items(wp, "y") == [("x", "relates"), ("z", "caused-by")];;
    assert would_block_cycle(wp, "x", "y") == True;;
}

test "blocker closure reaches cycle entry without disengage" {
    wp = load_workplane(
        [("d", "open", 1), ("a", "open", 1), ("b", "open", 1), ("c", "open", 1)],
        [("c", "a", "blocks"), ("b", "c", "blocks"), ("a", "b", "blocks"), ("a", "d", "blocks")],
    );
    assert blocking_closure(wp, "d") == ["a", "b", "c"];;
    assert is_blocked(wp, "d") == True;;
}

test "transitive blocks cycle rejected on add" {
    wp = load_workplane(
        [("a", "open", 1), ("b", "open", 1), ("c", "open", 1)],
        [("a", "b", "blocks"), ("b", "c", "blocks")],
    );
    raised = False;
    try {
        add_dependency(wp, "c", "a", "blocks");
        assert False, "should have raised";
    } except DependencyCycleError as err {
        assert str(err) == "dependency_cycle";;
        raised = True;
    }
    assert raised;;
}
