"""Recursive schema references — jacksmith15/statham-schema#63."""

node SchemaRegistry {
    has nodes: dict[str, SchemaNode] = {};
}

node SchemaNode {
    has nid: str;
    has has_default: bool = False;
    has dval: str = "";
}

edge PropEdge {
    has pname: str;
}

walker OrderWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has cycles: list[str] = [];

    can step with SchemaNode entry {
        print({"order_step": here.nid});
        if here.nid in self.claimed {
            self.cycles.append(here.nid);
            skip;
        }
        self.claimed[here.nid] = True;
        self.order.append(here.nid);
        kids: list[SchemaNode] = [];
        for ch in [here ->:PropEdge:->][?:SchemaNode] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            disengage;
        }
        idx: int = len(kids) - 1;
        while idx >= 0 {
            visit :0: [kids[idx]];
            idx = idx - 1;
        }
    }
}

walker BoundWalker {
    has claimed: dict[str, bool] = {};
    has limit: int = 5;
    has depth: int = 0;
    has result: dict = {};

    can bound with SchemaNode entry {
        print({"bound_step": here.nid, "depth": self.depth});
        out: dict = {};
        out["id"] = here.nid;
        out["default"] = here.dval;
        if self.depth >= self.limit {
            out["truncated"] = True;
            out["recursive"] = False;
            out["properties"] = {};
            self.result = out;
            disengage;
        }
        if here.nid in self.claimed {
            out["truncated"] = False;
            out["recursive"] = True;
            out["properties"] = {};
            self.result = out;
            disengage;
        }
        self.claimed[here.nid] = True;
        props: dict = {};
        edges: list[PropEdge] = [];
        for pe in [here ->:PropEdge:-] {
            edges.append(pe);
        }
        pnames: list[str] = [];
        for pe in edges {
            pnames.append(pe.pname);
        }
        pnames = sorted(pnames);
        for pn in pnames {
            for pe in edges {
                if pe.pname == pn {
                    tgts: list[SchemaNode] = [pe ->:->][?:SchemaNode];
                    if len(tgts) > 0 {
                        cw = tgts[0] spawn BoundWalker(
                            claimed=self.claimed,
                            limit=self.limit,
                            depth=self.depth + 1,
                            result={}
                        );
                        props[pn] = cw.result;
                    }
                }
            }
        }
        out["truncated"] = False;
        out["recursive"] = False;
        out["properties"] = props;
        self.result = out;
        disengage;
    }
}

def new_registry -> SchemaRegistry {
    reg = SchemaRegistry();
    root ++> reg;
    return reg;
}

def define_schema(reg: SchemaRegistry, nid: str, has_default: bool, dval: str) -> str {
    if nid in reg.nodes {
        return "";
    }
    nd = SchemaNode(nid=nid, has_default=has_default, dval=dval);
    reg.nodes[nid] = nd;
    reg ++> nd;
    return nid;
}

def link_property(reg: SchemaRegistry, from_id: str, pname: str, to_id: str) -> bool {
    if from_id not in reg.nodes {
        return False;
    }
    if to_id not in reg.nodes {
        return False;
    }
    src = reg.nodes[from_id] as SchemaNode;
    dst = reg.nodes[to_id] as SchemaNode;
    src +>:PropEdge(pname=pname):+> dst;
    return True;
}

def order_nodes(reg: SchemaRegistry, root_id: str) -> list[str] {
    if root_id not in reg.nodes {
        return [];
    }
    start = reg.nodes[root_id] as SchemaNode;
    wk = start spawn OrderWalker(claimed={}, order=[], cycles=[]);
    return wk.order;
}

def cycle_members(reg: SchemaRegistry, root_id: str) -> list[str] {
    if root_id not in reg.nodes {
        return [];
    }
    start = reg.nodes[root_id] as SchemaNode;
    wk = start spawn OrderWalker(claimed={}, order=[], cycles=[]);
    raw: list[str] = wk.cycles;
    seen: dict[str, bool] = {};
    out: list[str] = [];
    for x in sorted(raw) {
        if x not in seen {
            seen[x] = True;
            out.append(x);
        }
    }
    return out;
}

def bounded_default(reg: SchemaRegistry, root_id: str, limit: int) -> dict {
    if root_id not in reg.nodes {
        empty: dict = {};
        return empty;
    }
    start = reg.nodes[root_id] as SchemaNode;
    wk = start spawn BoundWalker(claimed={}, limit=limit, depth=0, result={});
    return wk.result;
}
