# iss_vllm-project__vllm-metal__360.jac
# Synthetic lift of vllm-project/vllm-metal#360 — MLA paged attention split:
# decode over compressed latent K/V (forward_mqa) vs prefill materialized MHA.

node GraphRoot { has rid: str; }
node MlaModel { has mid: str; has kind: str; }
node CacheBlk { has bid: str; has latent: bool; }
node AttnReq { has rid: str; has phase: str; has model_id: str; }
node KernelOpt { has kid: str; has flavor: str; }

edge ModelLink {}
edge CacheLink {}
edge KernelLink {}
edge PartitionLink {}

walker GatherBlocks {
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];
    can collect with AttnReq entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        for blk in [here ->:CacheLink:->][?:CacheBlk] {
            self.acc.append(blk.bid);
            print(blk.bid);
        }
        for nxt in [here ->:PartitionLink:->][?:AttnReq] {
            visit :0: [nxt];
        }
    }
    can collect_blk with CacheBlk entry {
        if here.bid in self.claimed { skip; }
        self.claimed[here.bid] = True;
        print(here.bid);
    }
}

walker GatherKernels {
    has claimed: dict[str, bool] = {};
    has acc: list[str] = [];
    can collect with AttnReq entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        for k in [here ->:KernelLink:->][?:KernelOpt] {
            self.acc.append(k.kid);
            print(k.kid);
        }
        for nxt in [here ->:PartitionLink:->][?:AttnReq] {
            visit :0: [nxt];
        }
    }
    can collect_k with KernelOpt entry {
        if here.kid in self.claimed { skip; }
        self.claimed[here.kid] = True;
        print(here.kid);
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};
    can demo with GraphRoot entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        print(here.rid);
    }
}

def new_graph(name: str) -> GraphRoot {
    g = GraphRoot(rid=name);
    root ++> g;
    return g;
}

def add_model(graph_root: GraphRoot, mid: str, kind: str) -> MlaModel {
    m = MlaModel(mid=mid, kind=kind);
    graph_root +>:ModelLink:+> m;
    return m;
}

def add_block(graph_root: GraphRoot, bid: str, latent: bool) -> CacheBlk {
    b = CacheBlk(bid=bid, latent=latent);
    graph_root +>:CacheLink:+> b;
    return b;
}

def add_request(graph_root: GraphRoot, rid: str, phase: str, model_id: str) -> AttnReq {
    r = AttnReq(rid=rid, phase=phase, model_id=model_id);
    graph_root +>:CacheLink:+> r;
    for m in [graph_root ->:ModelLink:->][?:MlaModel] {
        if m.mid == model_id {
            r +>:ModelLink:+> m;
        }
    }
    return r;
}

def link_block(req: AttnReq, blk: CacheBlk) {
    req +>:CacheLink:+> blk;
}

def attach_kernel(req: AttnReq, kid: str, flavor: str) -> KernelOpt {
    k = KernelOpt(kid=kid, flavor=flavor);
    req +>:KernelLink:+> k;
    return k;
}

def link_partition(a: AttnReq, b: AttnReq) {
    a +>:PartitionLink:+> b;
}

def find_request(graph_root: GraphRoot, rid: str) -> AttnReq | None {
    for r in [graph_root ->:CacheLink:->][?:AttnReq] {
        if r.rid == rid { return r; }
    }
    return None;
}

def reachable_blocks(graph_root: GraphRoot, rid: str) -> list[str] {
    tgt: AttnReq | None = find_request(graph_root, rid);
    if tgt is None { return []; }
    nd: AttnReq = tgt as AttnReq;
    w = nd spawn GatherBlocks(claimed={}, acc=[]);
    got: list[str] = (w as GatherBlocks).acc;
    return sorted(got);
}

def available_kernels(graph_root: GraphRoot, rid: str) -> list[str] {
    tgt: AttnReq | None = find_request(graph_root, rid);
    if tgt is None { return []; }
    nd: AttnReq = tgt as AttnReq;
    w = nd spawn GatherKernels(claimed={}, acc=[]);
    got: list[str] = (w as GatherKernels).acc;
    return sorted(got);
}

def routed_kernel(graph_root: GraphRoot, rid: str) -> str {
    tgt: AttnReq | None = find_request(graph_root, rid);
    if tgt is None { return ""; }
    req: AttnReq = tgt as AttnReq;
    # resolve model kind
    kind: str = "";
    for m in [req ->:ModelLink:->][?:MlaModel] {
        kind = m.kind;
    }
    # collect flavors
    flavors: dict[str, str] = {};
    for k in [req ->:KernelLink:->][?:KernelOpt] {
        flavors[k.flavor] = k.kid;
    }
    if req.phase == "decode" and kind == "mla" {
        if "absorbed_mla_decode" in flavors { return flavors["absorbed_mla_decode"]; }
        return "";
    }
    if req.phase == "prefill" and kind == "mla" {
        if "mha_materialized" in flavors { return flavors["mha_materialized"]; }
        return "";
    }
    if "split_kv" in flavors { return flavors["split_kv"]; }
    if "mha_materialized" in flavors { return flavors["mha_materialized"]; }
    return "";
}

with entry {
    g = new_graph("demo-mla");
    m = add_model(g, "mla-7b", "mla");
    r = add_request(g, "r-decode", "decode", "mla-7b");
    b = add_block(g, "latent-0", True);
    link_block(r, b);
    k1 = attach_kernel(r, "k-absorbed", "absorbed_mla_decode");
    dw = root spawn DemoWalker(claimed={});
    print("mla demo ready");
}
