"""Recursive directory listing — praat/praat.github.io#58."""

node FsNode {
    has cid: str;
    has path: str;
    has kind: str;
}

edge Child {}

obj FsGraph {
    has root_id: str;
    has by_id: dict[str, FsNode];
}

walker FileListWalker {
    has claimed: dict[str, bool] = {};
    has max_depth: int = -1;
    has cur_depth: int = 0;
    has paths: list[str] = [];

    can step with FsNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.paths.append(here.path);
        kids: list[FsNode] = [];
        if here.kind == "dir" {
            go: bool = False;
            if self.max_depth < 0 {
                go = True;
            } elif self.cur_depth < self.max_depth {
                go = True;
            }
            if go {
                kids = [here ->:Child:->][?:FsNode];
            }
        }
        print(f"listed {here.path} depth={self.cur_depth}");
        child_depth: int = self.cur_depth + 1;
        idx: int = len(kids) - 1;
        while idx >= 0 {
            self.cur_depth = child_depth;
            visit :0: [kids[idx]];
            idx -= 1;
        }
    }
}

def build_fs_graph(spec: list[list[str]]) -> FsGraph {
    g = FsGraph(root_id="", by_id={});
    i: int = 0;
    while i < len(spec) {
        row = spec[i];
        nd = FsNode(cid=row[0], path=row[1], kind=row[2]);
        g.by_id[row[0]] = nd;
        if row[3] == "" {
            g.root_id = row[0];
        }
        i += 1;
    }
    i = 0;
    while i < len(spec) {
        row = spec[i];
        nd = g.by_id[row[0]] as FsNode;
        root ++> nd;
        if row[3] != "" {
            par = g.by_id[row[3]] as FsNode;
            par +>:Child:+> nd;
        }
        i += 1;
    }
    return g;
}

def node_by_id(g: FsGraph, cid: str) -> FsNode | None {
    if cid in g.by_id {
        return g.by_id[cid] as FsNode;
    }
    return None;
}

def link_child(g: FsGraph, parent_cid: str, child_cid: str) -> bool {
    par = node_by_id(g, parent_cid);
    ch = node_by_id(g, child_cid);
    if par is None or ch is None {
        return False;
    }
    par +>:Child:+> ch;
    return True;
}

def recursive_file_list_full_path(g: FsGraph, max_depth: int) -> list[str] {
    if g.root_id == "" or g.root_id not in g.by_id {
        return [];
    }
    root_node = g.by_id[g.root_id] as FsNode;
    w = root_node spawn FileListWalker(
        max_depth=max_depth, claimed={}, cur_depth=0, paths=[]
    );
    out: list[str] = [];
    for p in w.paths {
        out.append(p);
    }
    return sorted(out);
}

with entry {
    demo: list[list[str]] = [
        ["r", "/demo", "dir", ""],
        ["f", "/demo/a.txt", "file", "r"],
    ];
    build_fs_graph(demo);
    root spawn FileListWalker(max_depth=-1, claimed={}, cur_depth=0, paths=[]);
}

test "full_depth_lists_all_paths" {
    spec: list[list[str]] = [
        ["r", "/demo", "dir", ""],
        ["f", "/demo/a.txt", "file", "r"],
        ["d", "/demo/sub", "dir", "r"],
        ["g", "/demo/sub/b.txt", "file", "d"],
    ];
    g = build_fs_graph(spec);
    got = recursive_file_list_full_path(g, -1);
    exp = ["/demo", "/demo/a.txt", "/demo/sub", "/demo/sub/b.txt"];
    assert got == exp;;
}

test "max_depth_one_stops_at_grandchildren" {
    spec: list[list[str]] = [
        ["r", "/demo", "dir", ""],
        ["f", "/demo/a.txt", "file", "r"],
        ["d", "/demo/sub", "dir", "r"],
        ["g", "/demo/sub/b.txt", "file", "d"],
    ];
    g = build_fs_graph(spec);
    got = recursive_file_list_full_path(g, 1);
    exp = ["/demo", "/demo/a.txt", "/demo/sub"];
    assert got == exp;;
}

test "max_depth_zero_root_only" {
    spec: list[list[str]] = [
        ["r", "/demo", "dir", ""],
        ["f", "/demo/a.txt", "file", "r"],
        ["d", "/demo/sub", "dir", "r"],
        ["g", "/demo/sub/b.txt", "file", "d"],
    ];
    g = build_fs_graph(spec);
    got = recursive_file_list_full_path(g, 0);
    exp = ["/demo"];
    assert got == exp;;
}

test "missing_root_returns_empty" {
    g = FsGraph(root_id="", by_id={});
    got = recursive_file_list_full_path(g, -1);
    assert got == [];;
}

test "node_by_id_hit_and_miss" {
    spec: list[list[str]] = [
        ["r", "/demo", "dir", ""],
    ];
    g = build_fs_graph(spec);
    hit = node_by_id(g, "r");
    miss = node_by_id(g, "nope");
    assert hit is not None;;
    assert hit.path == "/demo";;
    assert miss is None;;
}

test "link_child_valid_and_invalid" {
    spec: list[list[str]] = [
        ["r", "/demo", "dir", ""],
        ["f", "/demo/a.txt", "file", "r"],
    ];
    g = build_fs_graph(spec);
    ok = link_child(g, "r", "f");
    bad = link_child(g, "r", "missing");
    assert ok is True;;
    assert bad is False;;
}
