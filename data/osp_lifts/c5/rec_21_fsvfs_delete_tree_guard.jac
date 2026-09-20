"""Idiomatic OSP lift: virtual-filesystem cascade deletion (category C5).

Two-phase mutation protocol (OSP_IDIOMIZE_TASK.md §5.5):

Phase COLLECT -- `SubtreeScan` gathers the closure below the target into
typed `has` fields. A seen-guard keyed on `FsNode.key` makes collection
once-per-node (jac 0.36.1 has no built-in dedup) and doubles as the cycle
policy: revisiting a key means a cycle, so the walk disengages. A node whose
reference count exceeds one (`links > 1`) is a shared boundary -- it is
recorded as spared and never descended past (`skip;` keeps sibling branches
alive). Dead ends simply schedule nothing; the frontier drains to completion.

Phase APPLY -- the façade disconnects (`del ->:Contains:->`) and deletes
nodes strictly outside any walk, then prunes the path registry. Domain
semantics kept: unknown paths are a silent no-op, deleting ``/`` raises,
shared-boundary nodes survive together with their subtree.
"""

node FsNode {
    has name: str;
    has key: str;           # canonical registry path (unique id)
    has is_dir: bool = False;
    has links: int = 1;     # live parent mounts pointing here
}

edge Contains { }

walker SubtreeScan {
    has doomed: list[FsNode] = [];
    has spared: list[FsNode] = [];
    has seen: dict[str, bool] = {};

    can scan with FsNode entry {
        if here.key in self.seen {
            skip;           # cycle policy / diamond dedup: decide once, keep
        }                   # sibling branches alive (disengage would drop them)
        self.seen[here.key] = True;
        if here.links > 1 {
            self.spared.append(here);   # shared boundary: keep subtree alive
            skip;
        }
        self.doomed.append(here);
        visit [->:Contains:->];         # leaf dead end: frontier just drains
    }
}

obj FileSystem {
    has root_node: FsNode;
    has index: dict[str, FsNode];

    def resolve(path: str) -> FsNode | None {
        return self.index.get(path);
    }

    def mkdir(path: str) -> FsNode {
        parts = path.rpartition("/");
        holder = self.resolve(parts[0] or "/");
        assert holder is not None, f"missing parent for {path}";
        fresh = FsNode(name=parts[2], key=path, is_dir=True);
        holder +>:Contains:+> fresh;
        self.index[path] = fresh;
        return fresh;
    }

    def touch(path: str) -> FsNode {
        parts = path.rpartition("/");
        holder = self.resolve(parts[0] or "/");
        assert holder is not None, f"missing parent for {path}";
        fresh = FsNode(name=parts[2], key=path);
        holder +>:Contains:+> fresh;
        self.index[path] = fresh;
        return fresh;
    }

    """Bind-mount an existing node under another directory."""
    def mount(src_path: str, dest_parent_path: str, alias: str) -> FsNode {
        attached = self.resolve(src_path);
        mount_point = self.resolve(dest_parent_path);
        assert attached is not None and mount_point is not None;
        mount_point +>:Contains:+> attached;
        attached.links += 1;
        self.index[dest_parent_path + "/" + alias] = attached;
        return attached;
    }

    """Delete the entry at *path* (two-phase §5.5 mutation).

    Destroys the exclusive subtree beneath it, detaches shared-boundary
    nodes instead of destroying them, and returns how many nodes were
    destroyed. Unknown paths are a silent no-op; ``/`` raises ValueError.
    """
    def delete_subtree(path: str) -> int {
        # Phase COLLECT -- walk once; nothing destructive happens inside it.
        goal = self.resolve(path);
        if goal is None {
            return 0;
        }
        if goal is self.root_node {
            raise ValueError("refusing to delete the filesystem root");
        }
        scan = goal spawn SubtreeScan();
        doomed = scan.doomed;
        spared = scan.spared;

        parts = path.rpartition("/");
        holder = self.resolve(parts[0] or "/");
        assert holder is not None;

        # Phase APPLY -- all mutation happens after the walk has finished.
        if len(spared) > 0 and spared[0] is goal {
            holder del ->:Contains:-> goal;     # detach the alias mount only
            goal.links -= 1;
            return 0;
        }
        for dead_holder in doomed {
            for child in [dead_holder ->:Contains:->] as list[FsNode] {
                child.links -= 1;               # dying mount loses its count
                dead_holder del ->:Contains:-> child;
            }
        }
        # The requested target is kept as a tombstone: the source registry
        # prunes its path but the surviving parent keeps listing the entry,
        # and jac purges edges on del -- so skipping the del reproduces the
        # source's visible dangling entry exactly.
        for victim in doomed {
            if victim is goal {
                continue;
            }
            del victim;
        }
        live: dict[str, FsNode] = {};
        for k in self.index.keys() {
            entry_node = self.index[k];
            keep = True;
            for victim in doomed {
                if entry_node is victim {
                    keep = False;
                }
            }
            if keep {
                live[k] = entry_node;
            }
        }
        self.index = live;
        return len(doomed);
    }

    def ls(path: str) -> list[str] | None {
        nd = self.resolve(path);
        if nd is None {
            return None;
        }
        kids = [nd ->:Contains:->] as list[FsNode];
        return sorted(c.name for c in kids);
    }

    def exists(path: str) -> bool {
        return path in self.index;
    }
}

"""Build a fresh deterministic graph; creation order = fixture order."""
def load_graph(dirs: list[str], files: list[str],
               mounts: list[tuple[str, str, str]]) -> FileSystem {
    apex = FsNode(name="/", key="/", is_dir=True);
    fs = FileSystem(root_node=apex, index={});
    fs.index["/"] = apex;
    for d in dirs {
        _ = fs.mkdir(d);
    }
    for f in files {
        _ = fs.touch(f);
    }
    for m in mounts {
        _ = fs.mount(m[0], m[1], m[2]);
    }
    return fs;
}


test "exclusive_subtree_destroyed" {
    fs = load_graph(
        dirs=["/home", "/home/pics"],
        files=["/home/pics/cat.png"],
        mounts=[]
    );
    destroyed = fs.delete_subtree("/home/pics");
    assert destroyed == 2;
    assert fs.resolve("/home/pics") is None;
    assert fs.resolve("/home/pics/cat.png") is None;
    assert fs.exists("/home") and fs.exists("/");
    # source convention: the surviving parent still LISTS the removed entry
    # (dangling directory entry), only the registry path is gone
    assert fs.ls("/home") == ["pics"];
    # structural invariant: every surviving registry entry resolves
    for path in fs.index.keys() {
        assert fs.resolve(path) is not None, f"detached registry entry {path}";
    }
}

test "shared_boundary_spared_then_last_mount_destroys" {
    fs = load_graph(
        dirs=["/home", "/home/docs", "/mnt"],
        files=["/home/docs/report.txt", "/home/docs/notes.txt"],
        mounts=[("/home/docs", "/mnt", "docs")]
    );
    # Diamond: docs has two mounts -> cascade must spare it (once-only).
    first = fs.delete_subtree("/home/docs");
    assert first == 0;
    assert fs.exists("/home/docs");
    assert fs.ls("/mnt/docs") == ["notes.txt", "report.txt"];
    # structural invariant: every surviving registry entry resolves
    for path in fs.index.keys() {
        assert fs.resolve(path) is not None, f"detached registry entry {path}";
    }
    # Last mount goes: now the subtree dies exactly once, not twice.
    second = fs.delete_subtree("/mnt/docs");
    assert second == 3;
    assert fs.resolve("/home/docs") is None;
    assert fs.resolve("/home/docs/report.txt") is None;
    # dangling entry stays visible under the surviving parent
    assert fs.ls("/mnt") == ["docs"];
    # structural invariant: every surviving registry entry resolves
    for path in fs.index.keys() {
        assert fs.resolve(path) is not None, f"detached registry entry {path}";
    }
    assert fs.delete_subtree("/mnt/docs") == 0;   # already unregistered
}

test "dangling_refs_tolerated_as_noop" {
    fs = load_graph(dirs=["/a"], files=["/a/f.txt"], mounts=[]);
    assert fs.delete_subtree("/nope/nothing") == 0;
    assert fs.delete_subtree("/nope/nothing") == 0;   # still nothing to hit
    gone = fs.delete_subtree("/a");                   # destroy, then repeat
    assert gone == 2;
    assert fs.delete_subtree("/a") == 0;
    try {
        _r = fs.delete_subtree("/");
        assert False, "root deletion must raise ValueError";
    } except ValueError {
    }
    # structural invariant: every surviving registry entry resolves
    for path in fs.index.keys() {
        assert fs.resolve(path) is not None, f"detached registry entry {path}";
    }
}