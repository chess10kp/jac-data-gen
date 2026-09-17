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
