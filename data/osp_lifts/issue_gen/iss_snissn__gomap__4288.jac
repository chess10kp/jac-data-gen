node Tenant {
    has tid: str;
    has wid: str;
}
node SourceDoc {
    has doc_id: str;
    has tenant_id: str;
    has workspace_id: str;
}
node Chunk {
    has chunk_id: str;
    has doc_id: str;
    has parent_id: str;
    has tenant_id: str;
}

edge Contains {}
edge Depends {}
edge ChunkLink {}

walker TenantCollectWalk {
    has tid: str = "";
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can collect_tenant with Tenant entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        print(here.tid);
        for nxt in [here ->:Contains:->][?:SourceDoc] { visit :0: [nxt]; }
        for nxt2 in [here ->:Contains:->][?:Chunk] { visit :0: [nxt2]; }
    }
    can collect_doc with SourceDoc entry {
        if here.doc_id in self.claimed { skip; }
        self.claimed[here.doc_id] = True;
        print(here.doc_id);
        for ch in [here ->:Contains:->][?:Chunk] { visit :0: [ch]; }
        for dep in [here ->:Depends:->][?:SourceDoc] { visit :0: [dep]; }
    }
    can collect_chunk with Chunk entry {
        if here.chunk_id in self.claimed { skip; }
        self.claimed[here.chunk_id] = True;
        print(here.chunk_id);
        if here.tenant_id == self.tid {
            self.found.append(here.chunk_id);
        }
        for nxt in [here ->:ChunkLink:->][?:Chunk] { visit :0: [nxt]; }
    }
}

walker ParentCollapseWalk {
    has max_per: int = 1;
    has claimed: dict[str, bool] = {};
    has counts: dict[str, int] = {};
    has found: list[str] = [];
    can pc_tenant with Tenant entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        print(here.tid);
        for nxt in [here ->:Contains:->][?:SourceDoc] { visit :0: [nxt]; }
    }
    can pc_doc with SourceDoc entry {
        if here.doc_id in self.claimed { skip; }
        self.claimed[here.doc_id] = True;
        print(here.doc_id);
        for ch in [here ->:Contains:->][?:Chunk] { visit :0: [ch]; }
        for dep in [here ->:Depends:->][?:SourceDoc] { visit :0: [dep]; }
    }
    can pc_chunk with Chunk entry {
        if here.chunk_id in self.claimed { skip; }
        self.claimed[here.chunk_id] = True;
        print(here.chunk_id);
        cur: int = 0;
        if here.parent_id in self.counts {
            cur = self.counts[here.parent_id];
        }
        if cur < self.max_per {
            self.found.append(here.chunk_id);
            self.counts[here.parent_id] = cur + 1;
        }
        for nxt in [here ->:ChunkLink:->][?:Chunk] { visit :0: [nxt]; }
    }
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can reach_tenant with Tenant entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        print(here.tid);
        for nxt in [here ->:Contains:->][?:SourceDoc] { visit :0: [nxt]; }
    }
    can reach_doc with SourceDoc entry {
        if here.doc_id in self.claimed { skip; }
        self.claimed[here.doc_id] = True;
        print(here.doc_id);
        self.found.append(here.doc_id);
        for dep in [here ->:Depends:->][?:SourceDoc] { visit :0: [dep]; }
        for ch in [here ->:Contains:->][?:Chunk] { visit :0: [ch]; }
    }
    can reach_chunk with Chunk entry {
        if here.chunk_id in self.claimed { skip; }
        self.claimed[here.chunk_id] = True;
        print(here.chunk_id);
        self.found.append(here.chunk_id);
        for nxt in [here ->:ChunkLink:->][?:Chunk] { visit :0: [nxt]; }
    }
}

def make_tenant(tid: str, wid: str) -> Tenant {
    nd = Tenant(tid=tid, wid=wid);
    root ++> nd;
    return nd;
}
def add_document(graph_root: Tenant, doc_id: str, text: str) -> SourceDoc {
    nd = SourceDoc(doc_id=doc_id, tenant_id=graph_root.tid, workspace_id=graph_root.wid);
    graph_root +>:Contains:+> nd;
    return nd;
}
def add_chunk(parent: SourceDoc, chunk_id: str, text: str) -> Chunk {
    nd = Chunk(chunk_id=chunk_id, doc_id=parent.doc_id, parent_id=parent.doc_id, tenant_id=parent.tenant_id);
    parent +>:Contains:+> nd;
    return nd;
}
def add_dependency(src: SourceDoc, dst: SourceDoc) {
    src +>:Depends:+> dst;
}
def link_chunks(a: Chunk, b: Chunk) {
    a +>:ChunkLink:+> b;
}
def retrieve_for_tenant(graph_root: Tenant, tid: str, limit: int) -> list[str] {
    w = graph_root spawn TenantCollectWalk(tid=tid);
    out: list[str] = w.found;
    out = sorted(out);
    if len(out) > limit {
        sliced: list[str] = [];
        i: int = 0;
        for x in out {
            if i < limit { sliced.append(x); }
            i += 1;
        }
        return sliced;
    }
    return out;
}
def collapse_by_parent(graph_root: Tenant, max_per_parent: int) -> list[str] {
    w = graph_root spawn ParentCollapseWalk(max_per=max_per_parent);
    out: list[str] = w.found;
    return sorted(out);
}
def reachable_from(start: SourceDoc) -> list[str] {
    w = start spawn ReachWalk();
    out: list[str] = w.found;
    return sorted(out);
}

with entry {
    demo = Tenant(tid="demo", wid="w0");
    root ++> demo;
    w = demo spawn TenantCollectWalk(tid="demo");
    print(w.found);
}
