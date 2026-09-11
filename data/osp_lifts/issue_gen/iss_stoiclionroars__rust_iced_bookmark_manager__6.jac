node GNode {
    has nid: str;
    has ws: str;
    has kind: str;
    has alive: bool = True;
}
edge Contains {}

walker Finder {
    has target: str;
    has found: GNode | None = None;
    has claimed: dict[str, bool] = {};
    can find with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print(here.nid);
        if here.alive {
            if here.nid == self.target {
                self.found = here;
            }
        }
        kids: list[GNode] = [here ->:Contains:->][?:GNode];
        for k in kids { visit :0: [k]; }
    }
}

walker ReachCheck {
    has target: str;
    has hit: bool = False;
    has claimed: dict[str, bool] = {};
    can check with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print(here.nid);
        if here.nid == self.target { self.hit = True; }
        kids: list[GNode] = [here ->:Contains:->][?:GNode];
        for k in kids { visit :0: [k]; }
    }
}

walker DescendantsCollector {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can collect with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print(here.nid);
        if here.alive {
            self.out.append(here.nid);
        }
        kids: list[GNode] = [here ->:Contains:->][?:GNode];
        for k in kids { visit :0: [k]; }
    }
}

walker AllCollector {
    has claimed: dict[str, bool] = {};
    has nodes: list[GNode] = [];
    can collect with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print(here.nid);
        if here.alive {
            self.nodes.append(here);
        }
        kids: list[GNode] = [here ->:Contains:->][?:GNode];
        for k in kids { visit :0: [k]; }
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};
    can demo with GNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print(here.nid);
        kids: list[GNode] = [here ->:Contains:->][?:GNode];
        for k in kids { visit :0: [k]; }
    }
}

def find_node(nid: str) -> GNode | None {
    # scan all alive nodes via root
    w = root spawn Finder(target=nid);
    return w.found;
}

def create_workspace(wid: str) -> str {
    e = find_node(wid);
    if e is not None { return wid; }
    nd = GNode(nid=wid, ws=wid, kind="workspace");
    root ++> nd;
    print("created workspace");
    return wid;
}

def create_folder(fid: str, ws: str) -> str {
    e = find_node(fid);
    if e is not None { return fid; }
    nd = GNode(nid=fid, ws=ws, kind="folder");
    root ++> nd;
    print("created folder");
    return fid;
}

def link_node(parent: str, child: str) -> bool {
    p = find_node(parent);
    c = find_node(child);
    if p is None { return False; }
    if c is None { return False; }
    if parent == child { return False; }
    if p.ws != c.ws { return False; }
    # cycle check: is parent reachable from child ?
    chk = c spawn ReachCheck(target=parent);
    if chk.hit { return False; }
    # already linked check - allow duplicate as success
    # perform link
    p +>:Contains:+> c;
    print("linked");
    return True;
}

def get_descendants(nid: str) -> list[str] {
    n = find_node(nid);
    if n is None { return []; }
    w = n spawn DescendantsCollector();
    res: list[str] = [];
    for x in w.out {
        if x != nid { res.append(x); }
    }
    print("descendants done");
    return sorted(res);
}

def get_workspace_of_node(nid: str) -> str {
    n = find_node(nid);
    if n is None { return ""; }
    print(n.ws);
    return n.ws;
}

def recursive_delete(nid: str) -> list[str] {
    n = find_node(nid);
    if n is None { return []; }
    if !n.alive { return []; }
    w = n spawn DescendantsCollector();
    # two-phase: collect then mutate
    victims: list[GNode] = [];
    for vid in w.out {
        nd = find_node(vid);
        if nd is not None { victims.append(nd); }
    }
    deleted: list[str] = [];
    for v in victims {
        v.alive = False;
        deleted.append(v.nid);
    }
    # disconnect contains edges outside walk
    for v in victims {
        kids: list[GNode] = [v ->:Contains:->][?:GNode];
        for k in kids { v -:Contains:-> k; }
    }
    print("deleted");
    return sorted(deleted);
}

def export_dot() -> str {
    w = root spawn AllCollector();
    nodes: list[str] = [];
    for n in w.nodes { nodes.append(n.nid); }
    nodes = sorted(nodes);
    out: str = "digraph G {\n";
    for nid in nodes { out += "  " + nid + ";\n"; }
    for n in w.nodes {
        kids: list[GNode] = [n ->:Contains:->][?:GNode];
        for k in kids {
            if k.alive { out += "  " + n.nid + " -> " + k.nid + ";\n"; }
        }
    }
    out += "}";
    print(out);
    return out;
}

with entry {
    root spawn DemoWalker();
}
