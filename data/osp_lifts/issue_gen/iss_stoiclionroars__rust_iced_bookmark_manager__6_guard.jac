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

test "link_cycle_blocks_direct_and_indirect" {
    create_workspace("w_cycle");
    create_folder("A_c", "w_cycle");
    create_folder("B_c", "w_cycle");
    create_folder("C_c", "w_cycle");
    assert(link_node("A_c", "B_c"));
    assert(link_node("B_c", "C_c"));
    assert(!link_node("C_c", "A_c"));
    assert(!link_node("A_c", "A_c"));
    assert(get_descendants("A_c") == ["B_c", "C_c"]);
}

test "diamond_revisit_adversarial_order" {
    create_workspace("w_dia");
    create_folder("A_d", "w_dia");
    create_folder("B_d", "w_dia");
    create_folder("C_d", "w_dia");
    create_folder("D_d", "w_dia");
    assert(link_node("A_d", "B_d"));
    assert(link_node("A_d", "C_d"));
    assert(link_node("B_d", "D_d"));
    assert(link_node("C_d", "D_d"));
    # D_d is reachable via two paths; linking D_d -> A_d must still be detected as cycle
    assert(!link_node("D_d", "A_d"));
    # descendants of A_d must be exactly B,D,C without duplicates even though D visited twice
    assert(sorted(get_descendants("A_d")) == sorted(["B_d", "C_d", "D_d"]));
}

test "unknown_id_and_workspace_mismatch_tolerance" {
    create_workspace("w_u1");
    create_workspace("w_u2");
    create_folder("X_u", "w_u1");
    create_folder("Y_u", "w_u2");
    assert(!link_node("nope_parent", "X_u"));
    assert(!link_node("X_u", "nope_child"));
    assert(!link_node("X_u", "Y_u"));
    assert(get_descendants("ghost") == []);
    assert(get_workspace_of_node("ghost") == "");
    assert(recursive_delete("ghost") == []);
    assert(get_workspace_of_node("X_u") == "w_u1");
}

test "recursive_delete_and_export_dot" {
    create_workspace("w_del");
    create_folder("P_del", "w_del");
    create_folder("Q_del", "w_del");
    create_folder("SIB_del", "w_del");
    assert(link_node("w_del", "P_del"));
    assert(link_node("P_del", "Q_del"));
    assert(link_node("w_del", "SIB_del"));
    dot1 = export_dot();
    assert(dot1.contains("w_del -> P_del"));
    assert(dot1.contains("P_del -> Q_del"));
    got = recursive_delete("P_del");
    assert(sorted(got) == sorted(["P_del", "Q_del"]));
    assert(get_descendants("w_del") == ["SIB_del"]);
    assert(recursive_delete("P_del") == []);
    dot2 = export_dot();
    assert(!dot2.contains("P_del -> Q_del"));
}

test "cycle_preserved_across_save_semantics_no_duplicate_traversal" {
    create_workspace("w_save");
    create_folder("M_save", "w_save");
    create_folder("N_save", "w_save");
    assert(link_node("M_save", "N_save"));
    assert(!link_node("N_save", "M_save"));
    # ensure bfs does not loop and returns correct closure
    assert(get_descendants("M_save") == ["N_save"]);
    assert(get_descendants("N_save") == []);
}
