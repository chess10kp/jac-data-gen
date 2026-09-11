"""Workspace tree lifted to OSP (yogaprastyoo/hierarchical-task-api#79).

The id-keyed ``parent`` registry dies: a workspace's parent becomes one
typed ``ChildOf`` edge, descendant collection becomes a claiming
``DescCollect`` walker, and ascent becomes ``AncestorWalk``. The domain's
MAX_DEPTH rule survives verbatim -- moves re-check the depth budget using
the subtree-height measure instead of rescanning tables -- and ``archive``
follows the two-phase mutation contract: collect the id set first, delete
the nodes outside any walk. All mutable state lives on a per-instance
``WorkspaceTree`` handle; every test constructs a fresh instance.
"""

node Workspace {
    has wid: str;
    has name: str;
}

edge ChildOf: Workspace --> Workspace {}

"""Maximum tree level index (root sits at level 0); immutable domain rule."""
glob MAX_DEPTH: int = 3;


walker AncestorWalk {
    """Linear climb to the root; flags a corrupt loop."""
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    has hit_cycle: bool = False;

    can climb with Workspace entry {
        if here.wid in self.claimed {
            self.hit_cycle = True;
            return;
        }
        self.claimed[here.wid] = True;
        self.chain.append(here.wid);
        visit [->:ChildOf:->] else { disengage; }
    }
}


walker DescCollect {
    """Claims every descendant below the entry node once."""
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can descend with Workspace entry {
        if here.wid in self.claimed {
            return;  # revisit: skip silently
        }
        self.claimed[here.wid] = True;
        self.found.append(here.wid);
        for ch in [here <-:ChildOf:<-] {
            sub = DescCollect(claimed=self.claimed);
            ch spawn sub;
            self.found.extend(sub.found);
        }
    }
}


# Per-instance tree handle: the id lookup map is domain API; each test
# builds its own WorkspaceTree so no state leaks between runs.
obj WorkspaceTree {
    has ws: dict[str, Workspace] = {};

    def add(wid: str, name: str, parent: str | None = None) -> None {
        if parent is not None {
            if parent not in self.ws {
                raise KeyError(parent);
            }
            if self.depth_of(parent) + 1 > MAX_DEPTH - 1 {
                raise ValueError("max_depth");
            }
        }
        n = Workspace(wid=wid, name=name);
        root ++> n;
        self.ws[wid] = n;  # register before wiring: connect only via lookups
        if parent is not None {
            self.ws[wid] +>:ChildOf:+> self.ws[parent];
        }
    }

    # chain of ancestors above wid, excluding wid itself
    def ancestors(wid: str) -> list[str] {
        if wid not in self.ws {
            raise KeyError(wid);
        }
        w = self.ws[wid] spawn AncestorWalk(claimed={});
        if w.hit_cycle {
            raise ValueError("cycle");
        }
        return w.chain[1:];
    }

    def depth_of(wid: str) -> int {
        return len(self.ancestors(wid));
    }

    def collect_descendant_ids(wid: str) -> list[str] {
        # all descendant ids below wid (wid excluded)
        if wid not in self.ws {
            raise KeyError(wid);
        }
        w = self.ws[wid] spawn DescCollect(claimed={});
        return sorted(set(w.found) - {wid});
    }

    def subtree_height(wid: str) -> int {
        # levels in wid's subtree counting itself
        desc = self.collect_descendant_ids(wid);
        if len(desc) == 0 {
            return 1;
        }
        deepest = 0;
        for d in desc {
            dh = self.depth_of(d) - self.depth_of(wid);
            deepest = max(deepest, dh);
        }
        return deepest + 1;
    }

    def is_descendant(candidate: str, ancestor: str) -> bool {
        # true when candidate sits somewhere below ancestor
        if candidate not in self.ws or ancestor not in self.ws {
            raise KeyError(candidate);
        }
        return ancestor in self.ancestors(candidate);
    }

    def move(wid: str, new_parent: str | None) -> None {
        if wid not in self.ws or (
            new_parent is not None and new_parent not in self.ws
        ) {
            raise KeyError(wid);
        }
        if new_parent == wid or (
            new_parent is not None and self.is_descendant(new_parent, wid)
        ) {
            raise ValueError("cycle");
        }
        # depth budget: the moved subtree must still fit under the new parent
        base = 0 if new_parent is None else self.depth_of(new_parent);
        if base + self.subtree_height(wid) > MAX_DEPTH {
            raise ValueError("max_depth");
        }
        for old in [self.ws[wid] ->:ChildOf:->] {
            self.ws[wid] del ->:ChildOf:-> old;
        }
        if new_parent is not None {
            self.ws[wid] +>:ChildOf:+> self.ws[new_parent];
        }
    }

    def archive(wid: str) -> list[str] {
        # phase 1 collects the subtree, phase 2 deletes outside any walk;
        # returns sorted removed ids
        if wid not in self.ws {
            raise KeyError(wid);
        }
        doomed = [wid] + self.collect_descendant_ids(wid);
        for d in doomed {
            victim = self.ws[d];
            del victim;
            self.ws.pop(d, None);
        }
        return sorted(doomed);
    }
}
test "descendants, ancestors, depth" {
    t = WorkspaceTree();
    t.add("r1", "Root");
    t.add("eng", "Engineering", "r1");
    t.add("plat", "Platform", "eng");
    t.add("ops", "Ops", "r1");
    assert t.ancestors("plat") == ["eng", "r1"], t.ancestors("plat");
    assert t.collect_descendant_ids("r1") == ["eng", "ops", "plat"];
    assert t.collect_descendant_ids("eng") == ["plat"];
    assert t.collect_descendant_ids("plat") == [];
    assert t.is_descendant("plat", "r1");
    assert not t.is_descendant("plat", "ops");
    assert t.subtree_height("eng") == 2;
}

test "depth cap on add" {
    t = WorkspaceTree();
    t.add("r2", "Root");
    t.add("a", "A", "r2");
    t.add("b", "B", "a");
    try {
        t.add("c", "C", "b");
        assert False, "expected max_depth";
    } except ValueError {
        assert True;
    }
}

test "move re-points edge, refuses cycles and over-deep moves" {
    t = WorkspaceTree();
    t.add("r3", "Root");
    t.add("m1", "M1", "r3");
    t.add("m2", "M2", "r3");
    t.add("m3", "M3", "m2");
    t.move("m3", "m1");
    assert t.ancestors("m3") == ["m1", "r3"];
    try {
        t.move("m1", "m3");
        assert False, "expected cycle";
    } except ValueError {
        assert True;
    }
    # direct cycle attempt inside one tree
    t.add("p9", "P", "r3");
    t.add("q9", "Q", "p9");
    try {
        t.move("p9", "q9");  # p9 under its own child q9
        assert False, "expected cycle";
    } except ValueError {
        assert True;
    }
}

test "archive removes subtree two-phase" {
    t = WorkspaceTree();
    t.add("r4", "Root");
    t.add("k1", "K1", "r4");
    t.add("k2", "K2", "k1");
    removed = t.archive("k1");
    assert removed == ["k1", "k2"], removed;
    assert sorted(t.collect_descendant_ids("r4")) == [];
    try {
        t.ancestors("k2");
        assert False, "expected KeyError after delete";
    } except KeyError {
        assert True;
    }
}


test "fresh instances do not leak state" {
    a = WorkspaceTree();
    b = WorkspaceTree();
    a.add("solo", "Solo");
    try {
        b.ancestors("solo");
        assert False;
    } except KeyError {
        assert True;
    }
}
