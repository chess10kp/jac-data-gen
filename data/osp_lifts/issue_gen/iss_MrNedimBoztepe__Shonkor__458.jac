# iss_MrNedimBoztepe__Shonkor__458.jac
# MrNedimBoztepe/Shonkor#458 — AP3 bulk edge load + in-memory BFS blast radius (variant B).

node GNode {
  has cid: str;
}

edge Dep {}

obj GraphStore {
  has by_cid: dict[str, GNode] = {};
  has loaded_edges: int = 0;
}

walker RadiusBfs {
  has claimed: dict[str, bool] = {};
  has found: list[str] = [];
  has depth_cap: int = -1;
  has depth: int = 0;

  can step with GNode entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    self.found.append(here.cid);
    print(f"radius {here.cid} {self.depth}");
    if self.depth_cap >= 0 and self.depth >= self.depth_cap {
      disengage;
    }
    nxt: list[GNode] = [];
    for ch in [here ->:Dep:->][?:GNode] {
      nxt.append(ch);
    }
    if nxt {
      cids: list[str] = [];
      for nd in nxt {
        cids.append(nd.cid);
      }
      cids = sorted(cids);
      ordered: list[GNode] = [];
      for cid in cids {
        for nd in nxt {
          if nd.cid == cid {
            ordered.append(nd);
          }
        }
      }
      self.depth += 1;
      visit ordered;
      self.depth -= 1;
    } else {
      disengage;
    }
  }
}

walker ReverseReach {
  has claimed: dict[str, bool] = {};
  has found: list[str] = [];

  can rev with GNode entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    self.found.append(here.cid);
    print(f"reverse {here.cid}");
    preds: list[GNode] = [];
    for p in [here <-:Dep:<-][?:GNode] {
      preds.append(p);
    }
    if preds {
      pcids: list[str] = [];
      for nd in preds {
        pcids.append(nd.cid);
      }
      pcids = sorted(pcids);
      ordered_p: list[GNode] = [];
      for cid in pcids {
        for nd in preds {
          if nd.cid == cid {
            ordered_p.append(nd);
          }
        }
      }
      visit :0: ordered_p;
    } else {
      disengage;
    }
  }
}

def build_graph(edges: list[tuple[str, str]]) -> GraphStore {
  gs: GraphStore = GraphStore(by_cid={}, loaded_edges=0);
  for pair in edges {
    src_id: str = pair[0];
    dst_id: str = pair[1];
    if src_id not in gs.by_cid {
      sn: GNode = GNode(cid=src_id);
      root ++> sn;
      gs.by_cid[src_id] = sn;
    }
    if dst_id not in gs.by_cid {
      dn: GNode = GNode(cid=dst_id);
      root ++> dn;
      gs.by_cid[dst_id] = dn;
    }
    src_n: GNode = gs.by_cid[src_id] as GNode;
    dst_n: GNode = gs.by_cid[dst_id] as GNode;
    src_n +>:Dep:+> dst_n;
    gs.loaded_edges += 1;
  }
  return gs;
}

def blast_radius(gs: GraphStore, seed_cid: str, max_depth: int = -1) -> list[str] {
  if seed_cid not in gs.by_cid {
    empty: list[str] = [];
    return empty;
  }
  start: GNode = gs.by_cid[seed_cid] as GNode;
  w = start spawn RadiusBfs(claimed={}, found=[], depth_cap=max_depth, depth=0);
  return w.found;
}

def reverse_reachable(gs: GraphStore, seed_cid: str) -> list[str] {
  if seed_cid not in gs.by_cid {
    empty: list[str] = [];
    return empty;
  }
  start: GNode = gs.by_cid[seed_cid] as GNode;
  w = start spawn ReverseReach(claimed={}, found=[]);
  return w.found;
}

def bulk_edge_count(gs: GraphStore) -> int {
  return gs.loaded_edges;
}

def incident_lookup_count(gs: GraphStore) -> int {
  # Variant B: one bulk load, zero per-node roundtrips during traversal.
  return 0;
}
