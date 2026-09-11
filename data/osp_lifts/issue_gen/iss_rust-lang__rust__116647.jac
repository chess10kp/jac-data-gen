"""rust-lang/rust#116647 — recursive TypeVal trait-bound resolution without hang."""

node TypeNode {
    has cid: str;
    has kind: str = "leaf";
}

edge TypeArg {}
edge TraitImpl {}

obj TypeRegistry {
    has by_id: dict[str, TypeNode] = {};
}

def ensure_type(reg: TypeRegistry, cid: str, kind: str = "leaf") -> str {
    if cid in reg.by_id {
        return cid;
    }
    nd = TypeNode(cid=cid, kind=kind);
    reg.by_id[cid] = nd;
    root ++> nd;
    return cid;
}

def link_type_arg(reg: TypeRegistry, parent: str, child: str) {
    ensure_type(reg, parent, "multiply");
    ensure_type(reg, child);
    p = reg.by_id[parent];
    c = reg.by_id[child];
    p +>:TypeArg:+> c;
}

def link_trait_bound(reg: TypeRegistry, src: str, dst: str) {
    ensure_type(reg, src);
    ensure_type(reg, dst);
    s = reg.by_id[src];
    d = reg.by_id[dst];
    s +>:TraitImpl:+> d;
}

def build_multiply_chain(reg: TypeRegistry, depth: int, leaf: str = "Five") -> str {
    ensure_type(reg, leaf, "leaf");
    ensure_type(reg, "usize", "primitive");
    link_trait_bound(reg, leaf, "usize");
    if depth <= 0 {
        return leaf;
    }
    cur: str = leaf;
    for i in range(depth) {
        cid = "Mult_" + str(i);
        m_slot = "M_" + str(i);
        ensure_type(reg, cid, "multiply");
        ensure_type(reg, m_slot, "leaf");
        link_type_arg(reg, cid, cur);
        link_type_arg(reg, cid, m_slot);
        link_trait_bound(reg, cur, "usize");
        cur = cid;
    }
    return cur;
}

walker TraitResolve {
    has claimed: dict[str, bool] = {};
    has steps: int = 0;
    has max_steps: int = 256;
    has halted_cycle: bool = False;
    has satisfied: bool = True;

    can probe with TypeNode entry {
        print(["trait_probe", here.cid, self.steps]);
        if here.cid in self.claimed {
            self.halted_cycle = True;
            skip;
        }
        self.claimed[here.cid] = True;
        self.steps += 1;
        if self.steps > self.max_steps {
            self.satisfied = False;
            disengage;
        }
        if here.kind != "multiply" {
            disengage;
        }
        kids: list[TypeNode] = [];
        for ch in [here ->:TypeArg:->][?:TypeNode] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            self.satisfied = False;
            disengage;
        }
        n_node = kids[0];
        if n_node.kind == "leaf" {
            bounds: list[TypeNode] = [];
            for b in [n_node ->:TraitImpl:->][?:TypeNode] {
                bounds.append(b);
            }
            if len(bounds) == 0 {
                self.satisfied = False;
            }
            disengage;
        }
        visit :0: [n_node];
    }
}

def resolve_typeval_depth(reg: TypeRegistry, start_cid: str, max_steps: int = 256) -> dict[str, object] {
    if start_cid not in reg.by_id {
        out: dict[str, object] = {};
        out["steps"] = 0;
        out["cycle"] = False;
        out["ok"] = False;
        return out;
    }
    start_nd = reg.by_id[start_cid];
    w = start_nd spawn TraitResolve(max_steps=max_steps);
    out: dict[str, object] = {};
    out["steps"] = w.steps;
    out["cycle"] = w.halted_cycle;
    out["ok"] = w.satisfied and (not w.halted_cycle);
    return out;
}

with entry {
    reg: TypeRegistry = TypeRegistry();
    top = build_multiply_chain(reg, 3);
    top_nd = reg.by_id[top];
    w = top_nd spawn TraitResolve(max_steps=64);
    print(["demo", w.steps, w.halted_cycle, w.satisfied]);
}
