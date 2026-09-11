"""Guard: Waishnav/devspace#90."""

obj WorkspaceStore { has stamp: int = 0; }
node Dir { has path: str; has has_agent: bool; }
edge ChildDir {}

walker AgentDiscover {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Dir entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.has_agent { self.hits.append(here.path); }
        visit [->:ChildDir:->][?:Dir];
    }
}

def _find(path: str) -> Dir | None {
    for d in [-->][?:Dir] { if d.path == path { return d; } }
    return None;
}

def load_tree(specs: list[tuple[str, str | None, bool]]) -> WorkspaceStore {
    mp: dict[str, Dir] = {};
    for (p, _par, has_md) in specs {
        if p not in mp {
            n = Dir(path=p, has_agent=has_md);
            root ++> n;
            mp[p] = n;
        }
    }
    for (p, par, has_md) in specs {
        d = mp.get(p, None);
        if d is not None { d.has_agent = has_md; }
        if par is not None {
            parent = mp.get(par, None);
            child = mp.get(p, None);
            if parent is not None and child is not None {
                parent +>:ChildDir:+> child;
            }
        }
    }
    return WorkspaceStore(stamp=1);
}

def discover_agent_files(g: WorkspaceStore, root_path: str) -> list[str] {
    _ = g;
    anchor = _find(root_path);
    if anchor is None { return []; }
    w = anchor spawn AgentDiscover(claimed={}, hits=[]);
    return sorted(w.hits);
}

test "nested agent discovery main" {
    g = load_tree([
        ("/ws", None, False),
        ("/ws/p1", "/ws", True),
        ("/ws/p1/src", "/ws/p1", True),
        ("/ws/p1/src/deep", "/ws/p1/src", False),
        ("/ws/p2", "/ws", True),
    ]);
    assert discover_agent_files(g, "/ws") == ["/ws/p1", "/ws/p1/src", "/ws/p2"];
    assert discover_agent_files(g, "/ws/p1") == ["/ws/p1", "/ws/p1/src"];
    assert discover_agent_files(g, "/ws/p1/src/deep") == [];
}

test "unknown root tolerance" {
    g = load_tree([("/solo", None, True)]);
    assert discover_agent_files(g, "/nope") == [];
}

test "cycle revisit before deep closure" {
    g = load_tree([
        ("/a", None, False),
        ("/b", "/a", False),
        ("/c", "/b", True),
        ("/a", "/c", False),
    ]);
    assert discover_agent_files(g, "/a") == ["/c"];
}

test "adversarial breadth sibling agents" {
    g = load_tree([
        ("/r", None, False),
        ("/r/p1", "/r", True),
        ("/r/p2", "/r", True),
        ("/r/p3", "/r", True),
        ("/r/p1/nested", "/r/p1", True),
    ]);
    assert discover_agent_files(g, "/r") == [
        "/r/p1",
        "/r/p1/nested",
        "/r/p2",
        "/r/p3",
    ];
}
