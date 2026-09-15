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
