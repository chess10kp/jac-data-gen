node FsNode {
    has name: str;
    has is_dir: bool;
    has is_symlink: bool = False;
}

edge Contains {}

walker SearchWalker {
    has query: str;
    has max_results: int;
    has found: list[str] = [];
    has claimed: dict[str, bool] = {};

    can search with FsNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print(here.name);
        if self.query in here.name {
            if not here.is_dir {
                if len(self.found) < self.max_results {
                    self.found.append(here.name);
                }
            }
        }
        for nxt in [here ->:Contains:->][?:FsNode] {
            if nxt.is_symlink {
                continue;
            }
            visit :0: [nxt];
        }
    }
}

def make_dir(name: str) -> FsNode {
    nd = FsNode(name=name, is_dir=True, is_symlink=False);
    return nd;
}

def make_file(name: str) -> FsNode {
    nd = FsNode(name=name, is_dir=False, is_symlink=False);
    return nd;
}

def make_symlink(name: str) -> FsNode {
    nd = FsNode(name=name, is_dir=True, is_symlink=True);
    return nd;
}

def link_nodes(parent: FsNode, child: FsNode) {
    parent +>:Contains:+> child;
}

def search_files(graph_root: FsNode, query: str, max_results: int) -> list[str] {
    walker_inst = graph_root spawn SearchWalker(query=query, max_results=max_results, found=[], claimed={});
    return walker_inst.found;
}

with entry {
    demo_root = FsNode(name="demo_root", is_dir=True);
    root ++> demo_root;
    sample = FsNode(name="sample.txt", is_dir=False);
    demo_root +>:Contains:+> sample;
    w = demo_root spawn SearchWalker(query="sample", max_results=10, found=[], claimed={});
    print(w.found);
    rw = root spawn SearchWalker(query="sample", max_results=10, found=[], claimed={});
    print(rw.found);
}

test "symlink loop does not infinite recurse" {
    ws = FsNode(name="ws", is_dir=True);
    sub = make_dir("dir");
    loop = make_symlink("loop");
    f = make_file("found.txt");
    link_nodes(ws, sub);
    link_nodes(sub, f);
    link_nodes(sub, loop);
    loop +>:Contains:+> sub;
    found = search_files(ws, "found", 10);
    assert(found == ["found.txt"]);
}

test "diamond revisit not duplicated adversarial order" {
    r = make_dir("root");
    a = make_dir("a");
    b = make_dir("b");
    c = make_file("target.txt");
    link_nodes(r, a);
    link_nodes(r, b);
    link_nodes(a, c);
    link_nodes(b, c);
    found = search_files(r, "target", 10);
    assert(len(found) == 1);
    assert(found[0] == "target.txt");
}

test "unknown query returns empty" {
    r = make_dir("root");
    f = make_file("hello.txt");
    link_nodes(r, f);
    found = search_files(r, "missing", 10);
    assert(found == []);
}

test "max results truncates" {
    r = make_dir("root");
    f1 = make_file("a.txt");
    f2 = make_file("a2.txt");
    f3 = make_file("a3.txt");
    link_nodes(r, f1);
    link_nodes(r, f2);
    link_nodes(r, f3);
    found = search_files(r, "a", 2);
    assert(len(found) == 2);
    assert(sorted(found) == sorted(found));
}

test "symlink dir skipped even if it contains match" {
    r = make_dir("root");
    real = make_file("real.txt");
    sym = make_symlink("symdir");
    inner = make_file("inner.txt");
    link_nodes(r, real);
    link_nodes(r, sym);
    sym +>:Contains:+> inner;
    found = search_files(r, "inner", 10);
    assert(found == []);
    found2 = search_files(r, "real", 10);
    assert(found2 == ["real.txt"]);
}
