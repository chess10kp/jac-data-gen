"""Recursive Git submodule install ordering. Source: zed-pkg/zed-cli#177."""

node Submodule {
    has path: str;
}

edge ChildOf {}

walker ClosureWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has root_path: str = "";

    can begin with Root entry {
        for s in [-->][?:Submodule] {
            if s.path == self.root_path {
                visit [s];
            }
        }
    }

    can step with Submodule entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        self.order.append(here.path);
        visit [-->];
    }

    can finish with Root exit {
        report self.order;
    }
}

walker TopoWalker {
    has order: list[str] = [];
    has indeg: dict[str, int] = {};
    has ready: list[str] = [];
    has remaining: int = 0;
    has want: dict[str, bool] = {};

    can prep with Root entry {
        subs = [-->][?:Submodule];
        self.remaining = len(subs);
        for s in subs {
            parents = [s <--][?:Submodule];
            self.indeg[s.path] = len(parents);
        }
        self.ready = sorted([p for (p, d) in self.indeg.items() if d == 0]);
    }

    can drain with Root exit {
        while self.ready {
            path = self.ready.pop(0);
            self.order.append(path);
            self.remaining -= 1;
            for s in [-->][?:Submodule] {
                if s.path != path {
                    continue;
                }
                for child in [s -->][?:Submodule] {
                    self.indeg[child.path] -= 1;
                    if self.indeg[child.path] == 0 {
                        self.ready.append(child.path);
                        self.ready = sorted(self.ready);
                    }
                }
            }
        }
        if self.remaining != 0 {
            raise ValueError("recursive submodule cycle");
        }
        filtered: list[str] = [];
        for p in self.order {
            if self.want.get(p, False) {
                filtered.append(p);
            }
        }
        report filtered;
    }
}

def _wire_children(root_path: str, children: dict[str, list[str]]) {
    nodes: dict[str, Submodule] = {};
    if root_path not in nodes {
        nodes[root_path] = Submodule(path=root_path);
        root ++> nodes[root_path];
    }
    for (par, chs) in children.items() {
        if par not in nodes {
            nodes[par] = Submodule(path=par);
            root ++> nodes[par];
        }
        for ch in chs {
            if ch not in nodes {
                nodes[ch] = Submodule(path=ch);
                root ++> nodes[ch];
            }
            nodes[par] +>:ChildOf:+> nodes[ch];
        }
    }
}

def _wire_parent(parent: dict[str, str]) {
    nodes: dict[str, Submodule] = {};
    for (child, par) in parent.items() {
        if par not in nodes {
            nodes[par] = Submodule(path=par);
            root ++> nodes[par];
        }
        if child not in nodes {
            nodes[child] = Submodule(path=child);
            root ++> nodes[child];
        }
        nodes[par] +>:ChildOf:+> nodes[child];
    }
}

def submodule_closure(`root: str, children: dict[str, list[str]]) -> list[str] {
    _wire_children(`root, children);
    w = root spawn ClosureWalker(root_path=`root);
    return w.reports[0] if w.reports else [];
}

def submodule_order(paths: list[str], parent: dict[str, str]) -> list[str] {
    _wire_parent(parent);
    want: dict[str, bool] = {};
    for p in paths {
        want[p] = True;
    }
    for p in paths {
        found = False;
        for s in [-->][?:Submodule] {
            if s.path == p {
                found = True;
                break;
            }
        }
        if not found {
            fresh = Submodule(path=p);
            root ++> fresh;
        }
    }
    w = root spawn TopoWalker(want=want);
    return w.reports[0] if w.reports else [];
}

def submodule_cycle_safe(parent_map: dict[str, str]) -> bool {
    for start in parent_map {
        seen: dict[str, bool] = {};
        cur = start;
        while cur in parent_map {
            if seen.get(cur, False) {
                return False;
            }
            seen[cur] = True;
            cur = parent_map[cur];
        }
    }
    return True;
}

test "nested submodule install order" {
    parent = {"vendor/lib": "vendor", "vendor": "."};
    assert submodule_order(["vendor/lib", "vendor"], parent) == ["vendor", "vendor/lib"];
}

test "recursive closure chain" {
    children = {
        "vendor": ["vendor/lib"],
        "vendor/lib": ["vendor/lib/deep"],
    };
    assert submodule_closure("vendor", children) == [
        "vendor",
        "vendor/lib",
        "vendor/lib/deep",
    ];
}

test "diamond adversarial closure once per path" {
    children = {
        "d0": ["t", "a", "b"],
        "a": ["t"],
        "b": ["t"],
    };
    got = submodule_closure("d0", children);
    assert got.count("t") == 1;
    assert got == ["d0", "t", "a", "b"];
}

test "cycle parent map unsafe" {
    assert submodule_cycle_safe({"a": "b", "b": "a"}) is False;
    assert submodule_cycle_safe({"vendor/lib": "vendor"}) is True;
}

test "cycle install order raises ValueError" {
    try {
        submodule_order(["a", "b"], {"a": "b", "b": "a"});
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
}

test "isolated path orders alone" {
    assert submodule_order(["solo"], {}) == ["solo"];
}
