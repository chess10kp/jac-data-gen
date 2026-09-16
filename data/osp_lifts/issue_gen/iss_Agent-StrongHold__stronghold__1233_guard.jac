"""Agent-StrongHold/stronghold#1233 — memory relations traversal research scaffold."""

node Fact {
    has fid: str;
    has source_episode_id: str = "";
    has superseded_by: str = "";
}

edge Relates {
    has start_at: int = 0;
    has end_at: int = 999999;
    has source_episode_id: str = "";
}

walker FindFactWalker {
    has target: str = "";
    has hit: Fact | None = None;
    has claimed: dict[str, bool] = {};

    can seek with Fact entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        if here.fid == self.target {
            self.hit = here;
            disengage;
        }
        kids: list[Fact] = [here ->:Relates:->][?:Fact];
        idx: int = 0;
        while idx < len(kids) {
            visit :0: [kids[idx]];
            idx += 1;
        }
        raw_kids = [here ->];
        ri: int = 0;
        while ri < len(raw_kids) {
            cand = raw_kids[ri];
            if cand is Fact {
                ch = cand as Fact;
                if not (ch.fid in self.claimed) {
                    visit :0: [ch];
                }
            }
            ri += 1;
        }
    }
}

def find_fact(graph_root: Fact, fid: str) -> Fact | None {
    w = graph_root spawn FindFactWalker(target=fid, claimed={}, hit=None);
    return w.hit;
}

walker ReachWalker {
    has start_id: str = "";
    has max_hops: int = 2;
    has graph_root: Fact;
    has claimed: dict[str, bool] = {};
    has depth: dict[str, int] = {};
    has found: list[str] = [];

    can hop with Fact entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        cur: int = 0;
        if here.fid in self.depth {
            cur = self.depth[here.fid];
        }
        if here.fid != self.start_id {
            self.found.append(here.fid);
        }
        if cur >= self.max_hops {
            disengage;
        }
        outs: list[Fact] = [here ->:Relates:->][?:Fact];
        oi: int = 0;
        while oi < len(outs) {
            ch = outs[oi];
            if not (ch.fid in self.claimed) {
                self.depth[ch.fid] = cur + 1;
                visit :0: [ch];
            }
            oi += 1;
        }
    }
}

walker SuperWalker {
    has graph_root: Fact;
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can chase with Fact entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        if here.superseded_by != "" {
            self.chain.append(here.superseded_by);
            nxt = find_fact(self.graph_root, here.superseded_by);
            if nxt is not None {
                if not (nxt.fid in self.claimed) {
                    visit :0: [nxt];
                }
            } else {
                disengage;
            }
        } else {
            disengage;
        }
    }
}

walker ActiveRelWalker {
    has as_of: int = 0;
    has claimed: dict[str, bool] = {};
    has rows: list[str] = [];

    can scan with Fact entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        outs: list[Fact] = [here ->:Relates:->][?:Fact];
        ei: int = 0;
        while ei < len(outs) {
            dst = outs[ei];
            rel_edges: list[Relates] = [here ->:Relates:->][?:Relates];
            ri: int = 0;
            while ri < len(rel_edges) {
                e = rel_edges[ri];
                if e.start_at <= self.as_of and self.as_of <= e.end_at {
                    row = here.fid + "|" + dst.fid + "|" + e.source_episode_id;
                    self.rows.append(row);
                }
                ri += 1;
            }
            ei += 1;
        }
        raw_kids = [here ->];
        ki: int = 0;
        while ki < len(raw_kids) {
            cand = raw_kids[ki];
            if cand is Fact {
                ch = cand as Fact;
                if not (ch.fid in self.claimed) {
                    visit :0: [ch];
                }
            }
            ki += 1;
        }
    }
}

def build_memory_graph -> Fact {
    graph_root = Fact(fid="__root__");
    a = Fact(fid="A", source_episode_id="ep_a");
    b = Fact(fid="B", source_episode_id="ep_b");
    c = Fact(fid="C", source_episode_id="ep_c");
    d = Fact(fid="D", source_episode_id="ep_d", superseded_by="E");
    e = Fact(fid="E", source_episode_id="ep_e", superseded_by="F");
    f = Fact(fid="F", source_episode_id="ep_f");
    root ++> graph_root;
    graph_root ++> a;
    graph_root ++> b;
    graph_root ++> c;
    graph_root ++> d;
    graph_root ++> e;
    graph_root ++> f;
    a +>:Relates:+> b;
    a +>:Relates:+> c;
    b +>:Relates:+> d;
    c +>:Relates:+> d;
    return graph_root;
}

def reachable_within_hops(graph_root: Fact, start_id: str, max_hops: int) -> list[str] {
    start_nd = find_fact(graph_root, start_id);
    if start_nd is None {
        empty: list[str] = [];
        return empty;
    }
    depth0: dict[str, int] = {};
    depth0[start_id] = 0;
    w = start_nd spawn ReachWalker(
        start_id=start_id,
        max_hops=max_hops,
        graph_root=graph_root,
        claimed={},
        depth=depth0,
        found=[]
    );
    return sorted(w.found);
}

def supersession_chain(graph_root: Fact, fid: str) -> list[str] {
    start_nd = find_fact(graph_root, fid);
    if start_nd is None {
        empty: list[str] = [];
        return empty;
    }
    w = start_nd spawn SuperWalker(graph_root=graph_root, claimed={}, chain=[]);
    return w.chain;
}

def active_relations_at(graph_root: Fact, as_of: int) -> list[str] {
    w = graph_root spawn ActiveRelWalker(as_of=as_of, claimed={}, rows=[]);
    return sorted(w.rows);
}

test "find_fact_hit" {
    g = build_memory_graph();
    nd = find_fact(g, "A");
    assert nd is not None && nd.fid == "A";;
}

test "find_fact_missing" {
    g = build_memory_graph();
    nd = find_fact(g, "Z");
    assert nd is None;;
}

test "reachable_one_hop" {
    g = build_memory_graph();
    got = reachable_within_hops(g, "A", 1);
    assert got == ["B", "C"];;
}

test "reachable_two_hops" {
    g = build_memory_graph();
    got = reachable_within_hops(g, "A", 2);
    assert got == ["B", "C", "D"];;
}

test "supersession_chain" {
    g = build_memory_graph();
    got = supersession_chain(g, "D");
    assert got == ["E", "F"];;
}

test "active_relations_at" {
    g = build_memory_graph();
    got = active_relations_at(g, 0);
    assert got == ["A|B|", "A|C|", "B|D|", "C|D|"];;
}
