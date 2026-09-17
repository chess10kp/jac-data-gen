"""Agent-StrongHold/stronghold#1233 — multi-hop relation traversal and supersession cascade."""

node GraphRoot {
    has tag: str = "memory_layer";
}

node Fact {
    has fid: str;
    has label: str = "";
}

edge Rel {}
edge Supersedes {}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has hops: dict[str, int] = {};
    has max_hops: int = 2;
    has found: list[str] = [];

    can hop with Fact entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        hop = 0;
        if here.fid in self.hops { hop = self.hops[here.fid]; }
        if hop > self.max_hops { disengage; }
        self.found.append(here.fid);
        print(here.fid);
        nxt: list[Fact] = [here ->:Rel:->][?:Fact];
        queued: list[Fact] = [];
        for ch in nxt {
            nh = hop + 1;
            if nh <= self.max_hops {
                if ch.fid not in self.hops { self.hops[ch.fid] = nh; }
                queued.append(ch);
            }
        }
        if len(queued) > 0 { visit :0: queued; } else { disengage; }
    }
}

walker CascadeWalker {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can follow with Fact entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        self.chain.append(here.fid);
        print(here.fid);
        nxt: list[Fact] = [here ->:Supersedes:->][?:Fact];
        if len(nxt) > 0 { visit :0: nxt; } else { disengage; }
    }
}

walker PathWalker {
    has claimed: dict[str, bool] = {};
    has depths: dict[str, int] = {};
    has target: str = "";
    has max_depth: int = 3;
    has box: dict[str, bool] = {};

    can seek with Fact entry {
        if "hit" in self.box and self.box["hit"] { disengage; }
        if here.fid in self.claimed { skip; }
        dep = 0;
        if here.fid in self.depths { dep = self.depths[here.fid]; }
        if dep > self.max_depth { disengage; }
        self.claimed[here.fid] = True;
        print(here.fid);
        if here.fid == self.target {
            self.box["hit"] = True;
            disengage;
        }
        nxt: list[Fact] = [here ->:Rel:->][?:Fact];
        queued: list[Fact] = [];
        for ch in nxt {
            nd = dep + 1;
            if nd <= self.max_depth {
                if ch.fid not in self.depths { self.depths[ch.fid] = nd; }
                queued.append(ch);
            }
        }
        if len(queued) > 0 { visit :0: queued; } else { disengage; }
    }
}

def lookup_fact(gr: GraphRoot, fid: str) -> Fact | None {
    pending: list[Fact] = [gr ->][?:Fact];
    seen: dict[str, bool] = {};
    while len(pending) > 0 {
        cur = pending.pop();
        if cur.fid not in seen {
            seen[cur.fid] = True;
            if cur.fid == fid { return cur; }
            more: list[Fact] = [cur ->][?:Fact];
            for m in more { pending.append(m); }
        }
    }
    return None;
}

def build_memory_layer(
    fact_ids: list,
    rel_from: list,
    rel_to: list,
    sup_from: list,
    sup_to: list,
) -> GraphRoot {
    gr = GraphRoot();
    root ++> gr;
    by_id: dict[str, Fact] = {};
    for fid in fact_ids {
        nd = Fact(fid=fid);
        gr ++> nd;
        by_id[fid] = nd;
    }
    i = 0;
    while i < len(rel_from) {
        sf = rel_from[i];
        st = rel_to[i];
        if sf in by_id and st in by_id {
            by_id[sf] +>:Rel:+> by_id[st];
        }
        i += 1;
    }
    j = 0;
    while j < len(sup_from) {
        so = sup_from[j];
        sn = sup_to[j];
        if so in by_id and sn in by_id {
            by_id[so] +>:Supersedes:+> by_id[sn];
        }
        j += 1;
    }
    return gr;
}

def reachable_fact_ids(gr: GraphRoot, start_id: str, max_hops: int) -> list[str] {
    start = lookup_fact(gr, start_id);
    if start is None { return []; }
    hops0: dict[str, int] = {};
    hops0[start.fid] = 0;
    found: list[str] = [];
    w = start spawn ReachWalker(claimed={}, hops=hops0, max_hops=max_hops, found=found);
    _ = w.found;
    return sorted(found);
}

def supersession_chain(gr: GraphRoot, fact_id: str) -> list[str] {
    start = lookup_fact(gr, fact_id);
    if start is None { return []; }
    chain: list[str] = [];
    w = start spawn CascadeWalker(claimed={}, chain=chain);
    return w.chain;
}

def relation_path_exists(
    gr: GraphRoot,
    start_id: str,
    end_id: str,
    max_depth: int,
) -> bool {
    start = lookup_fact(gr, start_id);
    if start is None { return False; }
    if start_id == end_id { return True; }
    depths0: dict[str, int] = {};
    depths0[start.fid] = 0;
    box: dict[str, bool] = {};
    w = start spawn PathWalker(
        claimed={},
        depths=depths0,
        target=end_id,
        max_depth=max_depth,
        box=box,
    );
    if "hit" in w.box { return w.box["hit"]; }
    if "hit" in box { return box["hit"]; }
    return False;
}
