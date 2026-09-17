# Lifting Microsoft/msbuild#1576: recursive includes must honor Exclude
# patterns relative to the project folder.  Graph model: an FsNode tree
# (dirs and files as nodes, containment as typed Child edges).  A recursive
# glob walker collects every file reachable under a directory; excluded
# file names are pruned.  Cycle policy: claim-map (collected) + skip.

node FsNode {
    has name: str;
    has is_dir: bool = False;
}

edge Child {}

# Public API: recursive include ("**" glob) rooted at a directory node.
# Returns sorted file names, excluding any name listed in `excludes`.
def include_files(root: FsNode, excludes: list | None = None) -> list[str] {
    ex: dict[str, bool] = {};
    if excludes is None {
        excludes = [];
    }
    for x in excludes {
        ex[x] = True;
    }
    w = root spawn Globber(excluded=ex);
    got: list[str] = [];
    for k in w.collected {
        got.append(k);
    }
    return sorted(got);
}

# Public API: resolve a child by name; unknown names tolerate to None.
def find_node(root: FsNode, name: str) -> FsNode | None {
    for ch in [root ->:Child:->][?:FsNode] {
        if ch.name == name {
            return ch;
        }
    }
    return None;
}

# Public API: attach a child under a parent directory.
def add_child(parent: FsNode, name: str, is_dir: bool = False) -> FsNode {
    nd = FsNode(name=name, is_dir=is_dir);
    parent +>:Child:+> nd;
    return nd;
}

walker Globber {
    has excluded: dict[str, bool] = {};
    has collected: dict[str, bool] = {};

    can step with FsNode entry {
        if here.name in self.collected {
            skip;
        }
        if not here.is_dir and here.name in self.excluded {
            # exclude prunes the file but traversal of siblings continues
            self.collected[here.name] = False;
        } else {
            self.collected[here.name] = True;
        }
        kids: list[FsNode] = [here ->:Child:->][?:FsNode];
        visit kids else { disengage; }
    }
}

test "recursive_include_collects_sorted" {
    root = FsNode(name="parent", is_dir=True);
    proj = add_child(root, "ProjectFolder", True);
    add_child(proj, "a.txt");
    add_child(proj, "b.txt");
    got = include_files(root, ["Project.proj"]);
    assert got == ["a.txt", "b.txt"];
}

test "diamond_revisit_does_not_duplicate_files" {
    root = FsNode(name="root", is_dir=True);
    left = add_child(root, "L", True);
    right = add_child(root, "R", True);
    shared = FsNode(name="s.txt");
    left +>:Child:+> shared;
    right +>:Child:+> shared;
    got = include_files(root, None);
    assert got == ["s.txt"] and got == sorted(got);
}

test "exclude_prunes_named_file" {
    root = FsNode(name="proj", is_dir=True);
    add_child(root, "Project.proj");
    add_child(root, "code.cs");
    got = include_files(root, ["Project.proj"]);
    assert got == ["code.cs"];
}

test "unknown_exclude_is_tolerated" {
    root = FsNode(name="proj", is_dir=True);
    add_child(root, "a.txt");
    add_child(root, "b.txt");
    got = include_files(root, ["no_such_file.txt"]);
    assert sorted(got) == ["a.txt", "b.txt"];
}

test "find_node_unknown_returns_none" {
    root = FsNode(name="proj", is_dir=True);
    add_child(root, "a.txt");
    assert find_node(root, "a.txt") != None;
    assert find_node(root, "ghost.txt") == None;
}

test "empty_dir_yields_empty_list" {
    root = FsNode(name="empty", is_dir=True);
    assert include_files(root, None) == [];
}
