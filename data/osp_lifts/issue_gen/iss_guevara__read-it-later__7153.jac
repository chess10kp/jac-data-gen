"""guevara/read-it-later#7153 — nested-set hierarchy range queries."""

node NestedNode {
    has name: str;
    has lft: int = 0;
    has rgt: int = 0;
}

obj NestedSetStore {
    has nodes: dict[str, NestedNode] = {};
}

def load_nested_set(
    entries: list[tuple[str, int, int, str | None]],
) -> NestedSetStore {
    store = NestedSetStore();
    for (name, lft, rgt, _parent) in entries {
        nd = NestedNode(name=name, lft=lft, rgt=rgt);
        root ++> nd;
        store.nodes[name] = nd;
    }
    return store;
}

def nested_subtree(store: NestedSetStore, `root: str) -> list[str] {
    nd = store.nodes.get(`root, None);
    if nd is None { return []; }
    lft = nd.lft;
    rgt = nd.rgt;
    out: list[str] = [];
    for name in store.nodes.keys() {
        n = store.nodes.get(name, None);
        if n is not None and n.lft >= lft and n.rgt <= rgt {
            out.append(name);
        }
    }
    return sorted(out);
}

def nested_ancestors(store: NestedSetStore, `node: str) -> list[str] {
    nd = store.nodes.get(`node, None);
    if nd is None { return []; }
    nl = nd.lft;
    nr = nd.rgt;
    out: list[str] = [];
    for name in store.nodes.keys() {
        n = store.nodes.get(name, None);
        if n is not None and n.lft < nl and n.rgt > nr {
            out.append(name);
        }
    }
    for i in range(len(out)) {
        for j in range(i + 1, len(out)) {
            li = store.nodes.get(out[i], None);
            lj = store.nodes.get(out[j], None);
            if li is not None and lj is not None and li.lft > lj.lft {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
        }
    }
    return out;
}

def nested_depth(store: NestedSetStore, `node: str) -> int {
    return len(nested_ancestors(store, `node));
}

def contains_node(store: NestedSetStore, ancestor: str, descendant: str) -> bool {
    a = store.nodes.get(ancestor, None);
    d = store.nodes.get(descendant, None);
    if a is None or d is None { return False; }
    return a.lft <= d.lft and d.rgt <= a.rgt;
}
