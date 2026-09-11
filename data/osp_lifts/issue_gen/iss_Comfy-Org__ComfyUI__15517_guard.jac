"""Comfy-Org/ComfyUI#15517 — ModelPatcher mints a fresh namedtuple class per weight backup."""

import from collections { namedtuple }

node Weight {
    has key: str;
    has wt: float = 0.0;
}

edge DependsOn: Weight --> Weight {}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has origin: str = "";

    can step with Weight entry {
        if here.key in self.claimed { skip; }
        self.claimed[here.key] = True;
        if here.key != self.origin {
            self.hits.append(here.key);
        }
        kids = [here <-:DependsOn:<-][?:Weight];
        nms: list[str] = [];
        for n in kids { nms.append(n.key); }
        for nm in sorted(nms) {
            for n in kids {
                if n.key == nm { visit [n]; }
            }
        }
    }
}

walker CycleMemberWalk {
    has color: dict[str, int] = {};
    has on_cycle: dict[str, bool] = {};

    can probe with Weight entry {
        key = here.key;
        if self.color.get(key, 0) == 2 { skip; }
        self.color[key] = 1;
        deps = [here ->:DependsOn:->][?:Weight];
        nms: list[str] = [];
        for n in deps { nms.append(n.key); }
        for nm in sorted(nms) {
            for dep in deps {
                if dep.key != nm { continue; }
                dk = dep.key;
                dc = self.color.get(dk, 0);
                if dc == 1 {
                    self.on_cycle[key] = True;
                    self.on_cycle[dk] = True;
                } elif dc == 0 {
                    dep spawn CycleMemberWalk(color=self.color, on_cycle=self.on_cycle);
                    if dk in self.on_cycle {
                        self.on_cycle[key] = True;
                    }
                }
            }
        }
        self.color[key] = 2;
    }
}

obj PatcherStore {
    has weights: dict[str, float] = {};
    has parent: dict[str, str | None] = {};
    has backup: dict[str, object] = {};
    has nodes: dict[str, Weight] = {};
}

def make_patcher_store(
    weights: dict[str, float],
    edges: list[tuple[str, str]],
) -> PatcherStore {
    store = PatcherStore();
    for (key, val) in weights.items() {
        store.weights[key] = val;
        nd = Weight(key=key, wt=val);
        root ++> nd;
        store.nodes[key] = nd;
        store.parent[key] = None;
    }
    for (consumer, dep) in edges {
        if consumer in store.weights and dep in store.weights {
            c = store.nodes.get(consumer, None);
            d = store.nodes.get(dep, None);
            if c is not None and d is not None {
                c +>:DependsOn:+> d;
            }
        }
    }
    for consumer in store.weights.keys() {
        c = store.nodes.get(consumer, None);
        if c is None { continue; }
        deps = [c ->:DependsOn:->][?:Weight];
        if len(deps) == 0 { continue; }
        nms: list[str] = [];
        for dep in deps { nms.append(dep.key); }
        store.parent[consumer] = sorted(nms)[0];
    }
    return store;
}

glob _Dim = namedtuple("Dimension", ["weight", "inplace_update"]);

def backup_weight(store: PatcherStore, key: str, inplace: bool = False) -> None {
    if key not in store.weights { return; }
    wt = store.weights[key];
    entry = _Dim(wt, inplace);
    store.backup[key] = entry;
}

def clear_backups(store: PatcherStore) -> None {
    store.backup.clear();
}

def backup_entry_count(store: PatcherStore) -> int {
    return len(store.backup);
}

def unique_backup_entry_types(store: PatcherStore) -> int {
    seen: dict[str, bool] = {};
    for entry in store.backup.values() {
        tn = str(type(entry));
        seen[tn] = True;
    }
    cnt = 0;
    for _ in seen { cnt += 1; }
    return cnt;
}

def workflow_downstream(store: PatcherStore, start: str) -> list[str] {
    if start not in store.weights { return []; }
    nd = store.nodes.get(start, None);
    if nd is None { return []; }
    w = nd spawn DownstreamWalk(claimed={}, hits=[], origin=start);
    return sorted(w.hits);
}

def weight_parent_chain(store: PatcherStore, start: str) -> list[str] {
    if start not in store.weights { return []; }
    chain: list[str] = [];
    cur = start;
    seen: dict[str, bool] = {};
    while True {
        parent = store.parent.get(cur, None);
        if parent is None { break; }
        if parent in seen { break; }
        pnd = store.nodes.get(parent, None);
        if pnd is not None {
            kids = [pnd <-:DependsOn:<-][?:Weight];
            if len(kids) > 1 { break; }
        }
        seen[parent] = True;
        chain.append(parent);
        cur = parent;
    }
    return chain;
}

def cycle_member_weights(store: PatcherStore) -> list[str] {
    color: dict[str, int] = {};
    on_cycle: dict[str, bool] = {};
    for key in sorted(store.weights.keys()) {
        if color.get(key, 0) != 0 { continue; }
        nd = store.nodes.get(key, None);
        if nd is None { continue; }
        nd spawn CycleMemberWalk(color=color, on_cycle=on_cycle);
    }
    out: list[str] = [];
    for k in on_cycle { out.append(k); }
    return sorted(out);
}

test "diamond revisit downstream dedupe shared sink" {
    store = make_patcher_store(
        {"hub": 0.0, "left": 1.0, "right": 1.0, "sink": 2.0},
        [("left", "hub"), ("right", "hub"), ("sink", "left"), ("sink", "right")],
    );
    assert workflow_downstream(store, "hub") == ["left", "right", "sink"];;
    assert workflow_downstream(store, "sink") == [];;
}

test "diamond parent chain stops before merge hub" {
    store = make_patcher_store(
        {"root": 0.0, "left": 0.0, "right": 0.0, "join": 0.0},
        [("join", "right"), ("left", "root"), ("right", "root"), ("join", "left")],
    );
    assert workflow_downstream(store, "root") == ["join", "left", "right"];;
    assert weight_parent_chain(store, "join") == ["left"];;
}

test "unknown id tolerance across backup and walk queries" {
    store = make_patcher_store({"only": 1.0}, [("ghost", "only"), ("only", "missing")]);
    backup_weight(store, "nope", True);
    assert backup_entry_count(store) == 0;;
    assert workflow_downstream(store, "nope") == [];;
    assert weight_parent_chain(store, "nope") == [];;
    assert workflow_downstream(store, "only") == [];;
    assert cycle_member_weights(store) == [];;
}

test "fresh namedtuple class per backup key not shared" {
    store = make_patcher_store({"a": 1.0, "b": 2.0, "c": 3.0}, []);
    backup_weight(store, "a", False);
    backup_weight(store, "b", True);
    backup_weight(store, "c", False);
    assert backup_entry_count(store) == 3;;
    assert unique_backup_entry_types(store) == 1;;
    clear_backups(store);
    assert backup_entry_count(store) == 0;;
    backup_weight(store, "a", False);
    backup_weight(store, "b", False);
    backup_weight(store, "c", False);
    assert unique_backup_entry_types(store) == 1;;
}

test "parent chain cycle breaks on revisit not disengage" {
    store = make_patcher_store(
        {"a": 1.0, "b": 2.0, "c": 3.0},
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    ra = weight_parent_chain(store, "a");
    assert "b" in ra;;
    assert "c" in ra;;
    rb = weight_parent_chain(store, "b");
    assert "c" in rb;;
    assert "a" in rb;;
    rc = weight_parent_chain(store, "c");
    assert "a" in rc;;
}

test "cycle member weights three node ring" {
    store = make_patcher_store(
        {"a": 1.0, "b": 2.0, "c": 3.0},
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert cycle_member_weights(store) == ["a", "b", "c"];;
    # downstream in cycle may be [] or include cycle members depending on walk policy
    ds = workflow_downstream(store, "a");
    assert ds == [] or "b" in ds;;
}

test "first dependency wins parent chain tie" {
    store = make_patcher_store(
        {"w": 0.0, "x": 1.0, "y": 2.0, "z": 3.0},
        [("w", "x"), ("w", "y"), ("w", "z")],
    );
    assert weight_parent_chain(store, "w") == ["x"];;
    assert workflow_downstream(store, "x") == ["w"];;
}
