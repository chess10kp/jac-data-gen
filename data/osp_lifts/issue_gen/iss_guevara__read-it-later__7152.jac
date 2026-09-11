"""guevara/read-it-later#7152 — adjacency vs nested-set (MySQL EXPLAIN EXTENDED)."""

node HierNode {
    has name: str;
    has lft: int = 0;
    has rgt: int = 0;
}

edge ChildOf {}

obj HierarchyModel {
    has parent_of: dict[str, str | None] = {};
    has nodes: dict[str, HierNode] = {};
}

walker AdjDescWalk {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    has origin: str = "";

    can step with HierNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin { self.out.append(here.name); }
        children = [here ->:ChildOf:->][?:HierNode];
        nms: list[str] = [];
        for ch in children { nms.append(ch.name); }
        for nm in sorted(nms) {
            for ch in children {
                if ch.name == nm { visit ch; }
            }
        }
    }
}

def load_hierarchy(
    entries: list[tuple[str, int, int, str | None]],
) -> HierarchyModel {
    model = HierarchyModel();
    for (name, lft, rgt, parent) in entries {
        if parent is not None and not (parent in model.parent_of) {
            raise KeyError("unknown parent");
        }
        nd = model.nodes.get(name, None);
        if nd is None {
            nd = HierNode(name=name, lft=lft, rgt=rgt);
            root ++> nd;
            model.nodes[name] = nd;
        } else {
            nd.lft = lft;
            nd.rgt = rgt;
        }
        model.parent_of[name] = parent;
        if parent is not None {
            par = model.nodes.get(parent, None);
            if par is not None {
                exists = False;
                for ch in [par ->:ChildOf:->][?:HierNode] {
                    if ch.name == name { exists = True; }
                }
                if not exists { par +>:ChildOf:+> nd; }
            }
        }
    }
    return model;
}

def adj_session_descendants(model: HierarchyModel, `root: str) -> list[str] {
    if not (`root in model.parent_of) { return []; }
    nd = model.nodes.get(`root, None);
    if nd is None { return []; }
    w = nd spawn AdjDescWalk(claimed={}, out=[], origin=`root);
    return sorted(w.out);
}

def nested_spatial_subtree(model: HierarchyModel, `root: str) -> list[str] {
    nd = model.nodes.get(`root, None);
    if nd is None { return []; }
    lft = nd.lft;
    rgt = nd.rgt;
    out: list[str] = [];
    for name in model.nodes.keys() {
        if name == `root { continue; }
        n = model.nodes.get(name, None);
        if n is not None and n.lft >= lft and n.rgt <= rgt {
            out.append(name);
        }
    }
    return sorted(out);
}

def adj_session_depth(model: HierarchyModel, `node: str) -> int {
    if not (`node in model.parent_of) { return -1; }
    depth = 0;
    cur: str | None = `node;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur in seen { return -1; }
        seen[cur] = True;
        parent = model.parent_of.get(cur, None);
        if parent is None { break; }
        depth += 1;
        cur = parent;
    }
    return depth;
}

def nested_spatial_depth(model: HierarchyModel, `node: str) -> int {
    nd = model.nodes.get(`node, None);
    if nd is None { return -1; }
    nl = nd.lft;
    nr = nd.rgt;
    count = 0;
    for name in model.nodes.keys() {
        if name == `node { continue; }
        n = model.nodes.get(name, None);
        if n is not None and n.lft <= nl and n.rgt >= nr {
            count += 1;
        }
    }
    return count;
}

def models_agree_on_subtree(model: HierarchyModel, `root: str) -> bool {
    return adj_session_descendants(model, `root) == nested_spatial_subtree(model, `root);
}
