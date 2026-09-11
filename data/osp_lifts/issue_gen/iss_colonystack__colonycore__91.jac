"""Synthetic pre-OSP graph machinery for colonystack/colonycore#91.

Postgres benchmark suite prototype: relationship traversal probes over
in-memory entity graphs (Colony/Subject/Assignment/Protocol).
"""

node Entity {
    has eid: str;
}

edge ParentOf: Entity --> Entity {}
edge ColonySubject: Entity --> Entity {}
edge SubjectAssignment: Entity --> Entity {}
edge ProtocolStep: Entity --> Entity {}

def _rel_out(nd: Entity, kind: str) -> list[Entity] {
    match kind {
        case "colony_subject":
            return [nd ->:ColonySubject:->][?:Entity];
        case "subject_assignment":
            return [nd ->:SubjectAssignment:->][?:Entity];
        case "protocol_step":
            return [nd ->:ProtocolStep:->][?:Entity];
        case _:
            return [];
    }
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has max_depth: int = 16;
    has depth: int = 0;

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if self.depth >= self.max_depth { skip; }
        parents = [here ->:ParentOf:->][?:Entity];
        if not parents { skip; }
        par = parents[0];
        for p in parents {
            if p.eid < par.eid { par = p; }
        }
        if par.eid in self.claimed { skip; }
        self.found.append(par.eid);
        par spawn AncestorWalk(
            claimed=self.claimed,
            found=self.found,
            max_depth=self.max_depth,
            depth=self.depth + 1,
        );
    }
}

walker DescWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has max_depth: int = 16;
    has depth: int = 0;
    has origin: str = "";

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if here.eid != self.origin { self.reached.append(here.eid); }
        if self.depth >= self.max_depth { skip; }
        children = [here <-:ParentOf:<-][?:Entity];
        nms: list[str] = [];
        for n in children { nms.append(n.eid); }
        for nm in sorted(nms) {
            for n in children {
                if n.eid == nm {
                    n spawn DescWalk(
                        claimed=self.claimed,
                        reached=self.reached,
                        max_depth=self.max_depth,
                        depth=self.depth + 1,
                        origin=self.origin,
                    );
                }
            }
        }
    }
}

walker RelChainWalk {
    has rel_kinds: list[str] = [];
    has kind_idx: int = 0;
    has active: list[str] = [];
    has reached_claim: dict[str, bool] = {};
    has reached: list[str] = [];
    has lookup: dict[str, Entity] = {};

    can hop with Root entry {
        if self.kind_idx >= len(self.rel_kinds) { disengage; }
        kind = self.rel_kinds[self.kind_idx];
        nxt: list[str] = [];
        for src_id in self.active {
            src = self.lookup.get(src_id, None);
            if src is None { continue; }
            for tgt in _rel_out(src, kind) {
                if tgt.eid not in self.reached_claim {
                    self.reached_claim[tgt.eid] = True;
                    self.reached.append(tgt.eid);
                    nxt.append(tgt.eid);
                }
            }
        }
        next_idx = self.kind_idx + 1;
        if next_idx >= len(self.rel_kinds) { disengage; }
        nxt_sorted: list[str] = sorted(nxt);
        root spawn RelChainWalk(
            rel_kinds=self.rel_kinds,
            kind_idx=next_idx,
            active=nxt_sorted,
            reached_claim=self.reached_claim,
            reached=self.reached,
            lookup=self.lookup,
        );
    }
}

def _bootstrap() -> dict[str, Entity] {
    live = [root -->][?:Entity];
    if len(live) > 0 {
        nodes: dict[str, Entity] = {};
        for nd in live { nodes[nd.eid] = nd; }
        return nodes;
    }
    parent_of: dict[str, str | None] = {
        "col_a": None,
        "sub_1": "col_a",
        "sub_2": "col_a",
        "asn_1": "sub_1",
        "asn_2": "sub_1",
        "asn_3": "sub_2",
        "prt_p": None,
        "stp_1": "prt_p",
        "stp_2": "prt_p",
        "stp_3": "prt_p",
        "ver_1": "stp_1",
        "ver_2": "stp_2",
    };
    nodes: dict[str, Entity] = {};
    for (eid, _par) in parent_of.items() {
        nd = Entity(eid=eid);
        root ++> nd;
        nodes[eid] = nd;
    }
    for (child, par) in parent_of.items() {
        if par is None { continue; }
        c = nodes.get(child, None);
        p = nodes.get(par, None);
        if c is not None and p is not None { c +>:ParentOf:+> p; }
    }
    col = nodes.get("col_a", None);
    sub1 = nodes.get("sub_1", None);
    sub2 = nodes.get("sub_2", None);
    if col is not None and sub1 is not None { col +>:ColonySubject:+> sub1; }
    if col is not None and sub2 is not None { col +>:ColonySubject:+> sub2; }
    asn1 = nodes.get("asn_1", None);
    asn2 = nodes.get("asn_2", None);
    asn3 = nodes.get("asn_3", None);
    if sub1 is not None and asn1 is not None { sub1 +>:SubjectAssignment:+> asn1; }
    if sub1 is not None and asn2 is not None { sub1 +>:SubjectAssignment:+> asn2; }
    if sub2 is not None and asn3 is not None { sub2 +>:SubjectAssignment:+> asn3; }
    prt = nodes.get("prt_p", None);
    stp1 = nodes.get("stp_1", None);
    stp2 = nodes.get("stp_2", None);
    stp3 = nodes.get("stp_3", None);
    if prt is not None and stp1 is not None { prt +>:ProtocolStep:+> stp1; }
    if prt is not None and stp2 is not None { prt +>:ProtocolStep:+> stp2; }
    if prt is not None and stp3 is not None { prt +>:ProtocolStep:+> stp3; }
    return nodes;
}

def get_ancestors(entity_id: str, *, max_depth: int = 16) -> list[str] {
    nodes = _bootstrap();
    if entity_id not in nodes { return []; }
    nd = nodes[entity_id];
    w = nd spawn AncestorWalk(claimed={}, found=[], max_depth=max_depth, depth=0);
    return sorted(w.found);
}

def get_descendants(entity_id: str, *, max_depth: int = 16) -> list[str] {
    nodes = _bootstrap();
    if entity_id not in nodes { return []; }
    nd = nodes[entity_id];
    w = nd spawn DescWalk(
        claimed={}, reached=[], max_depth=max_depth, depth=0, origin=entity_id
    );
    return sorted(w.reached);
}

def traverse_rel_chain(start_id: str, rel_kinds: tuple[str, ...]) -> list[str] {
    nodes = _bootstrap();
    if len(rel_kinds) == 0 { return []; }
    kinds: list[str] = [];
    for k in rel_kinds { kinds.append(k); }
    w = root spawn RelChainWalk(
        rel_kinds=kinds,
        kind_idx=0,
        active=[start_id],
        reached_claim={},
        reached=[],
        lookup=nodes,
    );
    return sorted(w.reached);
}

def list_rel_targets(entity_id: str, rel_kind: str) -> list[str] {
    nodes = _bootstrap();
    nd = nodes.get(entity_id, None);
    if nd is None { return []; }
    out: list[str] = [];
    for tgt in _rel_out(nd, rel_kind) { out.append(tgt.eid); }
    return sorted(out);
}

def traversal_probe(entity_id: str) -> dict[str, int] {
    nodes = _bootstrap();
    if entity_id not in nodes {
        return {"visited": 0, "edges": 0, "depth": 0};
    }
    ancestors = get_ancestors(entity_id);
    descendants = get_descendants(entity_id);
    seen: dict[str, bool] = {};
    for a in ancestors { seen[a] = True; }
    for d in descendants { seen[d] = True; }
    seen[entity_id] = True;
    visited = 0;
    for _k in seen.keys() { visited += 1; }
    return {
        "visited": visited,
        "edges": len(ancestors) + len(descendants),
        "depth": len(ancestors),
    };
}
