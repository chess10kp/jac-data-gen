node Store { has sid: str = "store"; }
node Node { has nid: str; has workspace: str; has kind: str = "folder"; }
edge Holds {}
edge Contains {}

walker DemoWalker {
    has claimed: dict[str, bool] = {};
    can start with Store entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        print(here.sid);
        disengage;
    }
    can start_node with Node entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print(here.nid);
        disengage;
    }
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: bool = False;
    can reach with Node entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.nid == self.target {
            self.found = True;
            print("reach found");
        }
        kids: list[Node] = [];
        for nxt in [here ->:Contains:->][?:Node] {
            kids.append(nxt);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can collect with Node entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.out.append(here.nid);
        print(here.nid);
        kids: list[Node] = [];
        for nxt in [here ->:Contains:->][?:Node] {
            kids.append(nxt);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker CollectNodesWalker {
    has claimed: dict[str, bool] = {};
    has collected: list[Node] = [];
    can grab with Node entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.collected.append(here);
        print(here.nid);
        kids: list[Node] = [];
        for nxt in [here ->:Contains:->][?:Node] {
            kids.append(nxt);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def find_node(store: Store, nid: str) -> Node | None {
    for nd in [store ->:Holds:->][?:Node] {
        if nd.nid == nid {
            return nd;
        }
    }
    return None;
}

def new_store() -> Store {
    s = Store(sid="store");
    root +>:Holds:+> s;
    return s;
}

def create_node(store: Store, nid: str, workspace: str) -> bool {
    existing = find_node(store, nid);
    if existing is not None {
        return False;
    }
    nd = Node(nid=nid, workspace=workspace);
    store +>:Holds:+> nd;
    return True;
}

def link_node(store: Store, parent_id: str, child_id: str) -> bool {
    p = find_node(store, parent_id);
    c = find_node(store, child_id);
    if p is None { return False; }
    if c is None { return False; }
    if p.workspace != c.workspace { return False; }
    if parent_id == child_id { return False; }
    for nxt in [p ->:Contains:->][?:Node] {
        if nxt.nid == child_id { return False; }
    }
    w = c spawn ReachWalker(target=parent_id, claimed={});
    if w.found { return False; }
    p +>:Contains:+> c;
    return True;
}

def bfs_contains(store: Store, start_id: str) -> list[str] {
    s = find_node(store, start_id);
    if s is None { return []; }
    w = s spawn CollectWalker(claimed={}, out=[]);
    return w.out;
}

def get_workspace_of_node(store: Store, nid: str) -> str | None {
    nd = find_node(store, nid);
    if nd is None { return None; }
    return nd.workspace;
}

def recursive_delete(store: Store, nid: str) -> list[str] {
    nd = find_node(store, nid);
    if nd is None { return []; }
    w = nd spawn CollectNodesWalker(claimed={}, collected=[]);
    res: list[str] = [];
    for cur in w.collected {
        res.append(cur.nid);
    }
    for cur in w.collected {
        delete cur;
    }
    return res;
}

def export_dot(store: Store) -> str {
    out: str = "digraph G {\n";
    for nd in [store ->:Holds:->][?:Node] {
        for ch in [nd ->:Contains:->][?:Node] {
            out += "  " + nd.nid + " -> " + ch.nid + ";\n";
        }
    }
    out += "}\n";
    return out;
}

with entry {
    d = Store(sid="demo");
    root +>:Holds:+> d;
    root spawn DemoWalker();
}
