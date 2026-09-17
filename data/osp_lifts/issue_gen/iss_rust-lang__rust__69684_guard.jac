# Lifting rust-lang/rust#69684 — recursive fs::read_dir_all as OSP traversal.
# Filesystem modeled as a graph: DirEntry nodes, Contains edges, walker does
# the recursive enumeration with a claim-map for cycle safety.

node DirEntry {
    has path: str;
    has is_dir: bool = False;
}

edge Contains;

obj FsTree {
    has index: dict[str, DirEntry] = {};

    def add_node(path: str, is_dir: bool, parent_path: str | None = None) -> DirEntry {
        nd = DirEntry(path=path, is_dir=is_dir);
        self.index[path] = nd;
        if parent_path is not None {
            par = self.index.get(parent_path, None);
            if par is not None {
                par +>:Contains:+> nd;
            }
        }
        return nd;
    }

    def link(path_a: str, path_b: str) -> bool {
        # extra edge (cycle/diamond injection for adversarial traversal)
        a = self.index.get(path_a, None);
        b = self.index.get(path_b, None);
        if a is None or b is None {
            return False;
        }
        a +>:Contains:+> b;
        return True;
    }

    def get(path: str) -> DirEntry | None {
        return self.index.get(path, None);
    }
}

# non-recursive counterpart: immediate children, sorted
def read_dir(tree: FsTree, path: str) -> list[str] {
    nd = tree.get(path);
    if nd is None {
        return [];
    }
    kids: list[DirEntry] = [nd ->:Contains:->][?:DirEntry];
    names: list[str] = [];
    for ch in kids {
        names.append(ch.path);
    }
    names.sort();
    return names;
}

walker ReadAll {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];

    can step with DirEntry entry {
        if here.path in self.claimed {
            skip;  # cycle policy: claim-map + skip, never disengage
        }
        self.claimed[here.path] = True;
        self.out.append(here.path);
        kids: list[DirEntry] = [here ->:Contains:->][?:DirEntry];
        pairs: list[tuple] = [];
        for ch in kids {
            pairs.append((ch.path, ch));
        }
        pairs.sort();
        ordered: list[DirEntry] = [];
        for pr in pairs {
            ordered.append(pr[1]);
        }
        visit ordered else { disengage; }
    }
}

# recursive counterpart: full depth-first enumeration of all reachable entries
def read_dir_all(tree: FsTree, path: str) -> list[str] {
    nd = tree.get(path);
    if nd is None {
        return [];  # unknown-id tolerance matches Python source
    }
    w = nd spawn ReadAll(claimed={}, out=[]);
    res: list[str] = w.out;
    res.sort();
    return res;
}

walker Demo {
    can go with root entry {
        tree = FsTree();
        tree.add_node("proj", True, None);
        tree.add_node("proj/src", True, "proj");
        tree.add_node("proj/src/lib.rs", False, "proj/src");
        tree.add_node("proj/readme.md", False, "proj");
        everything: list[str] = read_dir_all(tree, "proj");
        print("read_dir_all:", everything);
        print("read_dir:", read_dir(tree, "proj"));
        print("missing:", read_dir_all(tree, "nope"));
    }
}

with entry {
    root spawn Demo();
}

test "recursive enumeration collects all depths" {
    tree = FsTree();
    tree.add_node("proj", True, None);
    tree.add_node("proj/src", True, "proj");
    tree.add_node("proj/src/lib.rs", False, "proj/src");
    tree.add_node("proj/src/deep/mod.rs", False, "proj/src");
    got = read_dir_all(tree, "proj");
    assert len(got) == 4;
    assert "proj/src/deep/mod.rs" in got;
}

test "diamond revisit does not duplicate and does not truncate" {
    tree = FsTree();
    tree.add_node("a", True, None);
    tree.add_node("a/b", True, "a");
    tree.add_node("a/c", True, "a");
    tree.add_node("leaf", False, "a/b");
    ok = tree.link("a", "leaf");
    assert ok;
    tree.link("a/c", "leaf");
    got = read_dir_all(tree, "a");
    dupes: int = len(got) - len(set(got));
    assert dupes == 0;
    assert got == ["a", "a/b", "a/c", "leaf"];
}

test "adversarial insertion order still sorted output" {
    tree = FsTree();
    tree.add_node("z", True, None);
    tree.add_node("z/zeta", False, "z");
    tree.add_node("z/alpha", False, "z");
    tree.add_node("z/mid", True, "z");
    tree.add_node("z/mid/x", False, "z/mid");
    got = read_dir_all(tree, "z");
    assert got == ["z", "z/alpha", "z/mid", "z/mid/x", "z/zeta"];
}

test "unknown path tolerated returning empty list" {
    tree = FsTree();
    tree.add_node("root", True, None);
    assert read_dir_all(tree, "ghost") == [];
    assert read_dir(tree, "ghost") == [];
}

test "read_dir is non-recursive and sorted" {
    tree = FsTree();
    tree.add_node("d", True, None);
    tree.add_node("d/sub", True, "d");
    tree.add_node("d/sub/hidden", False, "d/sub");
    tree.add_node("d/a.txt", False, "d");
    assert read_dir(tree, "d") == ["d/a.txt", "d/sub"];
    assert "d/sub/hidden" not in read_dir(tree, "d");
}

test "cycle edge is skipped safely" {
    tree = FsTree();
    tree.add_node("m", True, None);
    tree.add_node("m/n", True, "m");
    tree.link("m/n", "m");
    got = read_dir_all(tree, "m");
    assert got == ["m", "m/n"];
}
