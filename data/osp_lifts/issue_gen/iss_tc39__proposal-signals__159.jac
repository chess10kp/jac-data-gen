node BuildRoot { has name: str; }
node Lib { has lid: str; }
node Task { has tid: str; }
edge Contains {}
edge Depends {}
walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can follow_root with BuildRoot entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print(here.name);
        for lib in [here ->:Contains:->][?:Lib] { visit [lib]; }
    }
    can follow_lib with Lib entry {
        if here.lid in self.claimed { skip; }
        self.claimed[here.lid] = True;
        self.found.append(here.lid);
        print(here.lid);
        for t in [here ->:Contains:->][?:Task] { visit [t]; }
        for d in [here ->:Depends:->][?:Lib] { visit [d]; }
        for d2 in [here ->:Depends:->][?:Task] { visit [d2]; }
    }
    can follow_task with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        print(here.tid);
        for n in [here ->:Depends:->][?:Task] { visit [n]; }
        for n2 in [here ->:Depends:->][?:Lib] { visit [n2]; }
    }
}
walker CoalesceWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can gather_lib with Lib entry {
        if here.lid in self.claimed { skip; }
        self.claimed[here.lid] = True;
        print(here.lid);
        for t in [here ->:Contains:->][?:Task] { visit [t]; }
    }
    can gather_task with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.found.append(here.tid);
        print(here.tid);
        for n in [here ->:Depends:->][?:Task] { visit [n]; }
    }
}
def find_lib(graph_root: BuildRoot, lid: str) -> Lib | None {
    for cand in [graph_root ->:Contains:->][?:Lib] {
        if cand.lid == lid { return cand; }
    }
    return None;
}
def find_task(graph_root: BuildRoot, tid: str) -> Task | None {
    for lib in [graph_root ->:Contains:->][?:Lib] {
        for t in [lib ->:Contains:->][?:Task] {
            if t.tid == tid { return t; }
        }
    }
    return None;
}
def make_graph(name: str) -> BuildRoot {
    g: BuildRoot = BuildRoot(name=name);
    return g;
}
def add_library(graph_root: BuildRoot, lid: str) -> Lib {
    nd: Lib = Lib(lid=lid);
    graph_root +>:Contains:+> nd;
    return nd;
}
def add_task(graph_root: BuildRoot, lid: str, tid: str) -> Task | None {
    lib: Lib | None = find_lib(graph_root, lid);
    if lib is not None {
        nd: Task = Task(tid=tid);
        lib +>:Contains:+> nd;
        return nd;
    }
    return None;
}
def add_depends(graph_root: BuildRoot, src: str, dst: str) -> bool {
    src_t: Task | None = find_task(graph_root, src);
    src_l: Lib | None = None;
    if src_t is None { src_l = find_lib(graph_root, src); }
    dst_t: Task | None = find_task(graph_root, dst);
    dst_l: Lib | None = None;
    if dst_t is None { dst_l = find_lib(graph_root, dst); }
    if src_t is not None and dst_t is not None { src_t +>:Depends:+> dst_t; return True; }
    if src_t is not None and dst_l is not None { src_t +>:Depends:+> dst_l; return True; }
    if src_l is not None and dst_t is not None { src_l +>:Depends:+> dst_t; return True; }
    if src_l is not None and dst_l is not None { src_l +>:Depends:+> dst_l; return True; }
    return False;
}
def get_closure(graph_root: BuildRoot, start_id: str) -> list[str] {
    lib: Lib | None = find_lib(graph_root, start_id);
    if lib is not None {
        mp: dict[str, bool] = {};
        out: list[str] = [];
        w: ClosureWalker = lib spawn ClosureWalker(claimed=mp, found=out);
        return w.found;
    }
    task: Task | None = find_task(graph_root, start_id);
    if task is not None {
        mp2: dict[str, bool] = {};
        out2: list[str] = [];
        w2: ClosureWalker = task spawn ClosureWalker(claimed=mp2, found=out2);
        return w2.found;
    }
    if graph_root.name == start_id {
        mp3: dict[str, bool] = {};
        out3: list[str] = [];
        w3: ClosureWalker = graph_root spawn ClosureWalker(claimed=mp3, found=out3);
        return w3.found;
    }
    return [];
}
def get_coalesced(graph_root: BuildRoot, lid: str) -> list[str] {
    lib: Lib | None = find_lib(graph_root, lid);
    if lib is None { return []; }
    mp: dict[str, bool] = {};
    out: list[str] = [];
    w: CoalesceWalker = lib spawn CoalesceWalker(claimed=mp, found=out);
    return w.found;
}
with entry {
    g: BuildRoot = make_graph("demo");
    root ++> g;
    add_library(g, "demoLib");
    add_task(g, "demoLib", "demoTask");
    mp: dict[str, bool] = {};
    out: list[str] = [];
    w: ClosureWalker = g spawn ClosureWalker(claimed=mp, found=out);
    print("demo ready");
}
