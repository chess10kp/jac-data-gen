"""NumSim-Stack/numsim-cas#415 — candidate + hidden guards."""

obj TreeStore { has stamp: int = 0; }
node TreeNode { has nid: str; has value: int; has cached: int | None = None; }
edge ChildOf {}

walker HashFold {
    has claimed: dict[str, bool] = {};
    has acc: int = 0;
    can fold with TreeNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.cached is not None { self.acc = here.cached; disengage; }
        h = here.value;
        for ch in sorted([here ->:ChildOf:->][?:TreeNode], key=lambda x: x.nid) {
            h = (h * 31 + subtree_hash(TreeStore(), ch.nid)) & 0xFFFFFFFF;
        }
        here.cached = h;
        self.acc = h;
        disengage;
    }
}

walker InvalidateUp {
    has targets: list[str] = [];
    can start with TreeNode entry {
        self.targets.append(here.nid);
        parents = [here <-:ChildOf:<-][?:TreeNode];
        if parents { visit parents; } else { disengage; }
    }
}

def _find(nid: str) -> TreeNode | None {
    for n in [-->][?:TreeNode] { if n.nid == nid { return n; } }
    return None;
}

def load_tree(nodes: list[tuple[str, int, str | None]]) -> TreeStore {
    id_map: dict[str, TreeNode] = {};
    for (nid, val, _par) in nodes {
        if nid not in id_map {
            n = TreeNode(nid=nid, value=val);
            root ++> n;
            id_map[nid] = n;
        }
    }
    for (nid, val, par_id) in nodes {
        n = id_map[nid];
        n.value = val;
        if par_id is not None {
            p = id_map.get(par_id, None);
            if p is not None { p +>:ChildOf:+> n; }
        }
    }
    return TreeStore(stamp=1);
}

def subtree_hash(g: TreeStore, nid: str) -> int {
    _ = g;
    n = _find(nid);
    if n is None { return 0; }
    if n.cached is not None { return n.cached; }
    h = n.value;
    for ch in sorted([n ->:ChildOf:->][?:TreeNode], key=lambda x: x.nid) {
        h = (h * 31 + subtree_hash(g, ch.nid)) & 0xFFFFFFFF;
    }
    n.cached = h;
    return h;
}

def _apply_invalidate(targets: list[str]) -> None {
    for nid in targets { n = _find(nid); if n is not None { n.cached = None; } }
}

def set_value(g: TreeStore, nid: str, value: int) -> None {
    _ = g;
    n = _find(nid);
    if n is None { return; }
    n.value = value;
    w = n spawn InvalidateUp();
    _apply_invalidate(w.targets);
}

def add_child(g: TreeStore, parent: str, child: str, value: int) -> None {
    _ = g;
    p = _find(parent);
    if p is None { return; }
    if _find(child) is not None { return; }
    ch = TreeNode(nid=child, value=value);
    root ++> ch;
    p +>:ChildOf:+> ch;
    w = p spawn InvalidateUp();
    _apply_invalidate(w.targets + [child]);
}

def dirty_nodes(g: TreeStore) -> list[str] {
    _ = g;
    return sorted([n.nid for n in [-->][?:TreeNode] if n.cached is None]);
}

test "hash lazy + invalidation" {
    g = load_tree([("r", 1, None), ("a", 2, "r"), ("b", 3, "r")]);
    h0 = subtree_hash(g, "r");
    assert dirty_nodes(g) == [];
    set_value(g, "b", 30);
    assert dirty_nodes(g) == ["b", "r"];
    assert subtree_hash(g, "r") != h0;
}

test "diamond revisit hash fold" {
    g = load_tree([
        ("root", 0, None), ("l", 1, "root"), ("r", 2, "root"),
        ("sink", 3, "l"), ("sink2", 3, "r"),
    ]);
    add_child(g, "l", "sink", 9);
    assert subtree_hash(g, "root") > 0;
}
