"""Recursive filesystem traversal and destructive-op audit model.

mark3labs/mcp-filesystem-server#68
"""

import from collections { deque }

node File {
    has fid: str;
    has path: str;
    has is_dir: bool = False;
    has deleted: bool = False;
}

edge Child {}

obj FsStore {
    has nodes: dict[str, File] = {};
    has reactions: list[str] = [];
}

def make_store -> FsStore {
    return FsStore();
}

def add_node(store: FsStore, fid: str, path: str, is_dir: bool) -> File {
    nd = File(fid=fid, path=path, is_dir=is_dir);
    store.nodes[fid] = nd;
    root ++> nd;
    return nd;
}

def link_child(store: FsStore, parent_id: str, child_id: str) -> bool {
    if parent_id not in store.nodes {
        return False;
    }
    if child_id not in store.nodes {
        return False;
    }
    par = store.nodes[parent_id];
    ch = store.nodes[child_id];
    par +>:Child:+> ch;
    return True;
}

walker ListRecursive {
    has claimed: dict[str, bool] = {};
    has paths: list[str] = [];

    can step with File entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        self.paths.append(here.path);
        kids: list[File] = [];
        for ch in [here ->:Child:->][?:File] {
            kids.append(ch);
        }
        idx: int = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx -= 1;
        }
        print f"list {here.path}";
    }
}

walker CollectDelete {
    has claimed: dict[str, bool] = {};
    has fids: list[str] = [];

    can step with File entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        self.fids.append(here.fid);
        kids: list[File] = [];
        for ch in [here ->:Child:->][?:File] {
            kids.append(ch);
        }
        idx: int = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx -= 1;
        }
        print f"collect {here.fid}";
    }
}

def list_recursive(store: FsStore, root_id: str) -> list[str] {
    if root_id not in store.nodes {
        return [];
    }
    start = store.nodes[root_id];
    w = start spawn ListRecursive(claimed={}, paths=[]);
    return sorted(w.paths);
}

def delete_recursive(store: FsStore, target_id: str) -> list[str] {
    if target_id not in store.nodes {
        return [];
    }
    start = store.nodes[target_id];
    w = start spawn CollectDelete(claimed={}, fids=[]);
    deleted: list[str] = [];
    for fid in w.fids {
        if fid not in store.nodes {
            continue;
        }
        nd = store.nodes[fid];
        if nd.deleted {
            continue;
        }
        nd.deleted = True;
        deleted.append(nd.path);
        store.reactions.append(f"delete:{nd.path}");
    }
    return sorted(deleted);
}

def get_audit_reactions(store: FsStore) -> list[str] {
    return sorted(store.reactions);
}

with entry {
    demo = make_store();
    add_node(demo, "r", "/srv", True);
    add_node(demo, "a", "/srv/a.txt", False);
    link_child(demo, "r", "a");
    print list_recursive(demo, "r");
    print delete_recursive(demo, "r");
    print get_audit_reactions(demo);
}

"""Recursive filesystem traversal and destructive-op audit model.

mark3labs/mcp-filesystem-server#68
"""

import from collections { deque }

node File {
    has fid: str;
    has path: str;
    has is_dir: bool = False;
    has deleted: bool = False;
}

edge Child {}

obj FsStore {
    has nodes: dict[str, File] = {};
    has reactions: list[str] = [];
}

def make_store -> FsStore {
    return FsStore();
}

def add_node(store: FsStore, fid: str, path: str, is_dir: bool) -> File {
    nd = File(fid=fid, path=path, is_dir=is_dir);
    store.nodes[fid] = nd;
    root ++> nd;
    return nd;
}

def link_child(store: FsStore, parent_id: str, child_id: str) -> bool {
    if parent_id not in store.nodes {
        return False;
    }
    if child_id not in store.nodes {
        return False;
    }
    par = store.nodes[parent_id];
    ch = store.nodes[child_id];
    par +>:Child:+> ch;
    return True;
}

walker ListRecursive {
    has claimed: dict[str, bool] = {};
    has paths: list[str] = [];

    can step with File entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        self.paths.append(here.path);
        kids: list[File] = [];
        for ch in [here ->:Child:->][?:File] {
            kids.append(ch);
        }
        idx: int = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx -= 1;
        }
        print f"list {here.path}";
    }
}

walker CollectDelete {
    has claimed: dict[str, bool] = {};
    has fids: list[str] = [];

    can step with File entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        self.fids.append(here.fid);
        kids: list[File] = [];
        for ch in [here ->:Child:->][?:File] {
            kids.append(ch);
        }
        idx: int = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx -= 1;
        }
        print f"collect {here.fid}";
    }
}

def list_recursive(store: FsStore, root_id: str) -> list[str] {
    if root_id not in store.nodes {
        return [];
    }
    start = store.nodes[root_id];
    w = start spawn ListRecursive(claimed={}, paths=[]);
    return sorted(w.paths);
}

def delete_recursive(store: FsStore, target_id: str) -> list[str] {
    if target_id not in store.nodes {
        return [];
    }
    start = store.nodes[target_id];
    w = start spawn CollectDelete(claimed={}, fids=[]);
    deleted: list[str] = [];
    for fid in w.fids {
        if fid not in store.nodes {
            continue;
        }
        nd = store.nodes[fid];
        if nd.deleted {
            continue;
        }
        nd.deleted = True;
        deleted.append(nd.path);
        store.reactions.append(f"delete:{nd.path}");
    }
    return sorted(deleted);
}

def get_audit_reactions(store: FsStore) -> list[str] {
    return sorted(store.reactions);
}

test "list_recursive_unknown_id" {
    st = make_store();
    assert list_recursive(st, "missing") == [];
}

test "list_recursive_subtree" {
    st = make_store();
    add_node(st, "r", "/srv", True);
    add_node(st, "a", "/srv/a.txt", False);
    add_node(st, "b", "/srv/b", True);
    add_node(st, "c", "/srv/b/c.txt", False);
    link_child(st, "r", "a");
    link_child(st, "r", "b");
    link_child(st, "b", "c");
    got = list_recursive(st, "r");
    assert got == ["/srv", "/srv/a.txt", "/srv/b", "/srv/b/c.txt"];
}

test "list_recursive_cycle_skip" {
    st = make_store();
    add_node(st, "x", "/x", True);
    add_node(st, "y", "/x/y", True);
    link_child(st, "x", "y");
    link_child(st, "y", "x");
    got = list_recursive(st, "x");
    assert got == ["/x", "/x/y"];
}

test "delete_recursive_unknown_id" {
    st = make_store();
    assert delete_recursive(st, "nope") == [];
    assert get_audit_reactions(st) == [];
}

test "delete_recursive_collects_sorted" {
    st = make_store();
    add_node(st, "r", "/srv", True);
    add_node(st, "a", "/srv/a.txt", False);
    add_node(st, "b", "/srv/b.txt", False);
    link_child(st, "r", "a");
    link_child(st, "r", "b");
    got = delete_recursive(st, "r");
    assert got == ["/srv", "/srv/a.txt", "/srv/b.txt"];
    assert get_audit_reactions(st) == ["delete:/srv", "delete:/srv/a.txt", "delete:/srv/b.txt"];
}

test "delete_recursive_diamond_revisit" {
    st = make_store();
    add_node(st, "r", "/r", True);
    add_node(st, "m", "/r/m", True);
    add_node(st, "l", "/r/m/l", False);
    add_node(st, "d", "/r/d", False);
    link_child(st, "r", "m");
    link_child(st, "m", "l");
    link_child(st, "r", "d");
    link_child(st, "d", "l");
    got = delete_recursive(st, "r");
    assert got == ["/r", "/r/d", "/r/m", "/r/m/l"];
    assert len(get_audit_reactions(st)) == 4;
}
