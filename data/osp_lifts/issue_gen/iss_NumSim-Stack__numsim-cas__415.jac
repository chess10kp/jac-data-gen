"""NumSim-Stack/numsim-cas#415 — lazy subtree hash with OSP invalidation."""

obj TreeStore { has stamp: int = 0; }

node TreeNode {
    has nid: str;
    has value: int;
    has cached: int | None = None;
}

edge ChildOf {}

walker HashFold {
    has claimed: dict[str, bool] = {};
    has acc: int = 0;

    can fold with TreeNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.cached is not None {
            self.acc = (self.acc * 31 + here.cached) & 0xFFFFFFFF;
            disengage;
        }
        childs = [here ->:ChildOf:->][?:TreeNode];
        if childs {
            for ch in childs { ch spawn HashFold(claimed=self.claimed, acc=self.acc); }
        } else {
            self.acc = (self.acc * 31 + here.value) & 0xFFFFFFFF;
        }
        here.cached = self.acc;
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
    for n in [-->][?:TreeNode] {
        if n.nid == nid { return n; }
    }
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
    w = n spawn HashFold(claimed={}, acc=n.value);
    n.cached = w.acc;
    return n.cached;
}

def _apply_invalidate(targets: list[str]) -> None {
    for nid in targets {
        n = _find(nid);
        if n is not None { n.cached = None; }
    }
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
    out: list[str] = [];
    for n in [-->][?:TreeNode] {
        if n.cached is None { out.append(n.nid); }
    }
    return sorted(out);
}
