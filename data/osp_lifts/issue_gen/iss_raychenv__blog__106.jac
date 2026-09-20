# iss_raychenv__blog__106.jac
# raychenv/blog#106 — pythonds tree traversals lifted to OSP walkers.

node TreeNode {
    has cid: str;
    has label: str;
}

node TreeStore {
    has index: dict[str, TreeNode] = {};
}

edge Child {}

walker PreorderWalker {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];

    can walk with TreeNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.out.append(here.label);
        print here.label;
        kids: list[TreeNode] = [here ->:Child:->][?:TreeNode];
        visit :0: kids;
    }
}

walker PostorderWalker {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];

    can walk with TreeNode entry {
        if here.cid in self.claimed { skip; }
        kids: list[TreeNode] = [here ->:Child:->][?:TreeNode];
        visit kids;
        self.claimed[here.cid] = True;
        self.out.append(here.label);
        print here.label;
    }
}

walker LevelWalker {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    has queue: list[TreeNode] = [];

    can walk with TreeNode entry {
        self.queue.append(here);
        while len(self.queue) > 0 {
            cur = self.queue.pop(0);
            if cur.cid in self.claimed { continue; }
            self.claimed[cur.cid] = True;
            self.out.append(cur.label);
            print cur.label;
            chs: list[TreeNode] = [cur ->:Child:->][?:TreeNode];
            for ch in chs {
                self.queue.append(ch);
            }
        }
        disengage;
    }
}

walker DemoWalker {
    can boot entry {
        adj: dict[str, list[str]] = {"a": ["b"], "b": []};
        st = build_store(adj, None);
        if "a" in st.index {
            nd = st.index["a"];
            w = nd spawn PreorderWalker(claimed={});
            print w.out;
        }
    }
}

def build_store(adjacency: dict[str, list[str]], labels: dict[str, str] | None = None) -> TreeStore {
    st = TreeStore();
    lab: dict[str, str] = {};
    if labels is not None {
        lab = labels;
    }
    keys: list[str] = sorted(adjacency.keys());
    for cid in keys {
        lbl: str = cid;
        if cid in lab {
            lbl = lab[cid];
        }
        nd = TreeNode(cid=cid, label=lbl);
        root ++> nd;
        st.index[cid] = nd;
    }
    for cid in keys {
        kid_ids: list[str] = adjacency[cid];
        p = st.index[cid];
        for kid_id in kid_ids {
            if kid_id in st.index {
                k = st.index[kid_id];
                p +>:Child:+> k;
            }
        }
    }
    return st;
}

def preorder(store: TreeStore, root_id: str) -> list[str] {
    if root_id not in store.index {
        return [];
    }
    nd = store.index[root_id];
    w = nd spawn PreorderWalker(claimed={});
    return w.out;
}

def postorder(store: TreeStore, root_id: str) -> list[str] {
    if root_id not in store.index {
        return [];
    }
    nd = store.index[root_id];
    w = nd spawn PostorderWalker(claimed={});
    return w.out;
}

def levelorder(store: TreeStore, root_id: str) -> list[str] {
    if root_id not in store.index {
        return [];
    }
    nd = store.index[root_id];
    w = nd spawn LevelWalker(claimed={});
    return w.out;
}

with entry {
    root spawn DemoWalker;
}
