"""openai/codex#32684 — guard recursive USERPROFILE cleanup against path cycles."""

node Dir {
    has node_id: str;
    has name: str;
}

edge Child {}

obj DirGraph {
    has roots: list = [];

    def add_node(node_id: str, name: str) -> Dir {
        n = Dir(node_id=node_id, name=name);
        self.roots.append(n);
        return n;
    }

    def connect(parent: Dir, child: Dir) -> None {
        parent +>:Child:+> child;
    }

    def reachable(root_id: str) -> list[str] {
        root_n = None;
        for n in self.roots {
            if n.node_id == root_id {
                root_n = n;
            }
        }
        if root_n is None {
            return [];
        }
        w = root_n spawn ReachableWalker();
        return sorted(w.ids);
    }

    def safe_prune_order(root_id: str) -> list[str] {
        root_n = None;
        for n in self.roots {
            if n.node_id == root_id {
                root_n = n;
            }
        }
        if root_n is None {
            return [];
        }
        w = root_n spawn PruneOrderWalker();
        return w.order;
    }

    def has_cycle_from(root_id: str) -> bool {
        root_n = None;
        for n in self.roots {
            if n.node_id == root_id {
                root_n = n;
            }
        }
        if root_n is None {
            return False;
        }
        w = root_n spawn CycleWalker();
        return w.found;
    }
}

walker ReachableWalker {
    has ids: list[str] = [];
    has claimed: dict = {};

    can start with Dir entry {
        if self.claimed.get(here.node_id, False) {
            skip;
        }
        self.claimed[here.node_id] = True;
        self.ids.append(here.node_id);
        visit [-->];
    }
}

walker PruneOrderWalker {
    has order: list[str] = [];
    has claimed: dict = {};

    can post with Dir entry {
        if self.claimed.get(here.node_id, False) {
            skip;
        }
        self.claimed[here.node_id] = True;
        visit [-->];
        self.order.append(here.node_id);
    }
}

walker CycleWalker {
    has stack: list[str] = [];
    has found: bool = False;

    can dfs with Dir entry {
        if here.node_id in self.stack {
            self.found = True;
            skip;
        }
        self.stack = self.stack + [here.node_id];
        visit [-->];
        self.stack = self.stack[:-1];
    }
}

def _fixture() -> DirGraph {
    g = DirGraph();
    home = g.add_node("home", "USERPROFILE");
    docs = g.add_node("docs", "Documents");
    tmp = g.add_node("tmp", "tmp");
    cache = g.add_node("cache", "cache");
    link = g.add_node("link", "link");
    g.connect(home, docs);
    g.connect(home, tmp);
    g.connect(tmp, cache);
    g.connect(cache, link);
    g.connect(link, tmp);
    return g;
}

test "reachable multiset" {
    g = _fixture();
    assert g.reachable("home") == ["cache", "docs", "home", "link", "tmp"];
}

test "safe prune postorder with cycle" {
    g = _fixture();
    assert g.safe_prune_order("home") == ["docs", "link", "cache", "tmp", "home"];
}

test "cycle detected" {
    g = _fixture();
    assert g.has_cycle_from("home") is True;
}

test "acyclic diamond adversarial" {
    g = DirGraph();
    a = g.add_node("a", "a");
    b = g.add_node("b", "b");
    c = g.add_node("c", "c");
    d = g.add_node("d", "d");
    g.connect(a, b);
    g.connect(a, c);
    g.connect(b, d);
    g.connect(c, d);
    assert g.reachable("a") == ["a", "b", "c", "d"];
    assert g.has_cycle_from("a") is False;
}
