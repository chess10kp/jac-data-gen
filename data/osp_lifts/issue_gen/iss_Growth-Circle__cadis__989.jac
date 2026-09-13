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
