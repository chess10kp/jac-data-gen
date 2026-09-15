"""Graph view execution order — jpalczewski/kajet-turbo#188."""

node Milestone {
    has nid: str;
    has degree: int = 0;
}

edge Blocks {}
edge Link {}

walker TopoWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Milestone entry {
        if here.nid in self.claimed { skip; }
        preds: list[Milestone] = [];
        for p in [here <-:Blocks:<-][?:Milestone] {
            preds.append(p);
        }
        i = 0;
        while i < len(preds) {
            j = i + 1;
            while j < len(preds) {
                if preds[j].nid < preds[i].nid {
                    tmp = preds[i];
                    preds[i] = preds[j];
                    preds[j] = tmp;
                }
                j += 1;
            }
            i += 1;
        }
        for p in preds {
            if p.nid not in self.claimed {
                visit p;
                skip;
            }
        }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        print {"topo": here.nid};
    }
}

walker HoodWalker {
    has claimed: dict[str, bool] = {};
    has max_hops: int = 0;
    has depths: dict[str, int] = {};
    has found: list[str] = [];

    can step with Milestone entry {
        if here.nid in self.claimed { skip; }
        cur = 0;
        if here.nid in self.depths {
            cur = self.depths[here.nid];
        }
        if cur > self.max_hops { disengage; }
        self.claimed[here.nid] = True;
        self.found.append(here.nid);
        print {"hood": here.nid, "d": cur};
        if cur < self.max_hops {
            kids: list[Milestone] = [];
            for ch in [here ->:Link:->][?:Milestone] {
                kids.append(ch);
            }
            k = 0;
            while k < len(kids) {
                self.depths[kids[k].nid] = cur + 1;
                visit :0: kids[k];
                k += 1;
            }
        }
    }
}

walker SweepWalker {
    has claimed: dict[str, bool] = {};
    has rows: list[Milestone] = [];

    can step with Milestone entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.rows.append(here);
        print {"sweep": here.nid};
        kids: list[Milestone] = [];
        for ch in [here ->:Blocks:->][?:Milestone] { kids.append(ch); }
        for ch in [here <-:Blocks:<-][?:Milestone] { kids.append(ch); }
        for ch in [here ->:Link:->][?:Milestone] { kids.append(ch); }
        for ch in [here <-:Link:<-][?:Milestone] { kids.append(ch); }
        i = 0;
        while i < len(kids) {
            visit kids[i];
            i += 1;
        }
    }
}

walker FindWalker {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has hit: Milestone | None = None;

    can step with Milestone entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        print {"find": here.nid};
        if here.nid == self.target {
            self.hit = here;
            disengage;
        }
        kids: list[Milestone] = [];
        for ch in [here ->:Blocks:->][?:Milestone] { kids.append(ch); }
        for ch in [here <-:Blocks:<-][?:Milestone] { kids.append(ch); }
        for ch in [here ->:Link:->][?:Milestone] { kids.append(ch); }
        for ch in [here <-:Link:<-][?:Milestone] { kids.append(ch); }
        i = 0;
        while i < len(kids) {
            visit kids[i];
            i += 1;
        }
    }
}

def _sort_ids(xs: list[str]) -> list[str] {
    out: list[str] = [];
    i = 0;
    while i < len(xs) {
        out.append(xs[i]);
        i += 1;
    }
    i = 0;
    while i < len(out) {
        j = i + 1;
        while j < len(out) {
            if out[j] < out[i] {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def _sort_by_degree(xs: list[Milestone]) -> list[Milestone] {
    out: list[Milestone] = [];
    i = 0;
    while i < len(xs) {
        out.append(xs[i]);
        i += 1;
    }
    i = 0;
    while i < len(out) {
        j = i + 1;
        while j < len(out) {
            swap = False;
            if out[j].degree > out[i].degree { swap = True; }
            if out[j].degree == out[i].degree and out[j].nid < out[i].nid { swap = True; }
            if swap {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def _sort_by_nid(xs: list[Milestone]) -> list[Milestone] {
    out: list[Milestone] = [];
    i = 0;
    while i < len(xs) {
        out.append(xs[i]);
        i += 1;
    }
    i = 0;
    while i < len(out) {
        j = i + 1;
        while j < len(out) {
            if out[j].nid < out[i].nid {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def build_kajet_graph -> Milestone {
    m133 = Milestone(nid="133", degree=3);
    m134 = Milestone(nid="134", degree=1);
    m135 = Milestone(nid="135", degree=2);
    m136 = Milestone(nid="136", degree=2);
    m137 = Milestone(nid="137", degree=0);
    m138 = Milestone(nid="138", degree=0);
    root ++> m133;
    root ++> m134;
    root ++> m135;
    root ++> m136;
    root ++> m137;
    root ++> m138;
    m133 +>:Blocks:+> m134;
    m133 +>:Blocks:+> m135;
    m133 +>:Blocks:+> m136;
    m134 +>:Blocks:+> m137;
    m135 +>:Blocks:+> m137;
    m135 +>:Blocks:+> m138;
    m136 +>:Blocks:+> m137;
    m136 +>:Blocks:+> m138;
    return m133;
}

def build_diamond_graph -> Milestone {
    r = Milestone(nid="root", degree=2);
    a = Milestone(nid="a", degree=1);
    b = Milestone(nid="b", degree=1);
    c = Milestone(nid="c", degree=2);
    root ++> r;
    root ++> a;
    root ++> b;
    root ++> c;
    r +>:Link:+> b;
    b +>:Link:+> c;
    return r;
}

def topological_order(entry: Milestone) -> list[str] {
    w = entry spawn TopoWalker(claimed={});
    return w.order;
}

def neighborhood(entry: Milestone, max_hops: int) -> list[str] {
    w = entry spawn HoodWalker(claimed={}, max_hops=max_hops, depths={});
    return _sort_ids(w.found);
}

def sweep_milestones(entry: Milestone) -> list[str] {
    w = entry spawn SweepWalker(claimed={});
    ids: list[str] = [];
    for m in w.rows {
        ids.append(m.nid);
    }
    return _sort_ids(ids);
}

def find_milestone(entry: Milestone, target: str) -> Milestone | None {
    w = entry spawn FindWalker(claimed={}, target=target);
    return w.hit;
}

def milestones_by_degree(nodes: list[Milestone]) -> list[str] {
    sorted_nodes = _sort_by_degree(nodes);
    ids: list[str] = [];
    for m in sorted_nodes {
        ids.append(m.nid);
    }
    return ids;
}

def milestones_by_nid(nodes: list[Milestone]) -> list[str] {
    sorted_nodes = _sort_by_nid(nodes);
    ids: list[str] = [];
    for m in sorted_nodes {
        ids.append(m.nid);
    }
    return ids;
}

test "topo_sink_137" {
    with entry {
        g = build_kajet_graph();
        m137 = find_milestone(g, "137");
        ord = topological_order(m137);
        assert (ord == ["133", "134", "135", "136", "137"]);;
    }
}

test "topo_sink_138" {
    with entry {
        g = build_kajet_graph();
        m138 = find_milestone(g, "138");
        ord = topological_order(m138);
        assert (ord == ["133", "134", "135", "136", "138"]);;
    }
}

test "hood_diamond_two_hops" {
    with entry {
        r = build_diamond_graph();
        hood = neighborhood(r, 2);
        assert (hood == ["b", "c", "root"]);;
    }
}

test "sweep_diamond_link_closure" {
    with entry {
        r = build_diamond_graph();
        ids = sweep_milestones(r);
        assert (ids == ["b", "c", "root"]);;
    }
}

test "find_missing_target" {
    with entry {
        r = build_diamond_graph();
        hit = find_milestone(r, "missing");
        assert (hit is None);;
    }
}

test "milestones_by_degree_sort" {
    with entry {
        g = build_kajet_graph();
        m133 = find_milestone(g, "133");
        m134 = find_milestone(g, "134");
        m137 = find_milestone(g, "137");
        nodes: list[Milestone] = [];
        nodes.append(m137);
        nodes.append(m133);
        nodes.append(m134);
        ids = milestones_by_degree(nodes);
        assert (ids == ["133", "134", "137"]);;
    }
}
