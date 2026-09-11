"""July-NANA/OpenAnban#123 — candidate + hidden guards."""

obj SkillStore { has stamp: int = 0; }
node Dir { has path: str; has has_skill: bool; }
edge ChildDir {}

walker SkillDiscover {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with Dir entry {
        if here.path in self.claimed { skip; }
        self.claimed[here.path] = True;
        if here.has_skill { self.hits.append(here.path); }
        visit [->:ChildDir:->][?:Dir];
    }
}

def _find(path: str) -> Dir | None {
    for d in [-->][?:Dir] { if d.path == path { return d; } }
    return None;
}

def load_tree(specs: list[tuple[str, str | None, bool]]) -> SkillStore {
    mp: dict[str, Dir] = {};
    for (p, _par, has_md) in specs {
        if p not in mp {
            n = Dir(path=p, has_skill=has_md);
            root ++> n;
            mp[p] = n;
        }
    }
    for (p, par, has_md) in specs {
        d = mp.get(p, None);
        if d is not None { d.has_skill = has_md; }
        if par is not None {
            parent = mp.get(par, None);
            child = mp.get(p, None);
            if parent is not None and child is not None {
                parent +>:ChildDir:+> child;
            }
        }
    }
    return SkillStore(stamp=1);
}

def discover_skills(g: SkillStore, `root: str) -> list[str] {
    _ = g;
    anchor = _find(`root);
    if anchor is None { return []; }
    w = anchor spawn SkillDiscover(claimed={}, hits=[]);
    return sorted(w.hits);
}

test "nested skill discovery main" {
    g = load_tree([
        ("/skills", None, False),
        ("/skills/coding", "/skills", True),
        ("/skills/coding/python", "/skills/coding", True),
        ("/skills/coding/python/advanced", "/skills/coding/python", False),
        ("/skills/coding/tools", "/skills/coding", True),
        ("/skills/docs", "/skills", True),
    ]);
    assert discover_skills(g, "/skills") == [
        "/skills/coding",
        "/skills/coding/python",
        "/skills/coding/tools",
        "/skills/docs",
    ];
    assert discover_skills(g, "/skills/coding") == [
        "/skills/coding",
        "/skills/coding/python",
        "/skills/coding/tools",
    ];
    assert discover_skills(g, "/skills/coding/python/advanced") == [];
}

test "unknown root tolerance" {
    g = load_tree([("/solo", None, True)]);
    assert discover_skills(g, "/nope") == [];
}

test "cycle revisit before deep closure" {
    g = load_tree([
        ("/a", None, False),
        ("/b", "/a", False),
        ("/c", "/b", True),
        ("/a", "/c", False),
    ]);
    assert discover_skills(g, "/a") == ["/c"];
}

test "adversarial breadth sibling skills" {
    g = load_tree([
        ("/r", None, False),
        ("/r/w1", "/r", True),
        ("/r/w2", "/r", True),
        ("/r/w3", "/r", True),
        ("/r/w1/deep", "/r/w1", True),
    ]);
    assert discover_skills(g, "/r") == [
        "/r/w1",
        "/r/w1/deep",
        "/r/w2",
        "/r/w3",
    ];
}
