"""lutaml/ogc-gml#21 circular require graph among generated schema types."""

node SchemaRegistry {
    has by_id: dict[str, SchemaType] = {};
}

node SchemaType {
    has type_id: str;
}

edge Requires {}

walker CycleProbeWalker {
    has claimed: dict[str, bool] = {};
    has on_path: dict[str, bool] = {};
    has path_stack: list[str] = [];
    has cycle_ids: list[str] = [];
    has origin: str = "";

    can probe with SchemaType entry {
        if here.type_id in self.claimed {
            skip;
        }
        if here.type_id in self.on_path {
            self.cycle_ids.append(here.type_id);
            pi = 0;
            while pi < len(self.path_stack) {
                self.cycle_ids.append(self.path_stack[pi]);
                pi += 1;
            }
            print "cycle_back", self.origin, here.type_id;
            skip;
        }
        self.claimed[here.type_id] = True;
        self.on_path[here.type_id] = True;
        self.path_stack.append(here.type_id);
        kids: list[SchemaType] = [];
        for ch in [here ->:Requires:->][?:SchemaType] {
            kids.append(ch);
        }
        if len(kids) > 0 {
            visit :0: kids;
        }
        self.on_path[here.type_id] = False;
        if len(self.path_stack) > 0 {
            top = self.path_stack[len(self.path_stack) - 1];
            if top == here.type_id {
                self.path_stack.pop();
            }
        }
    }
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: bool = False;

    can reach with SchemaType entry {
        if self.found {
            disengage;
        }
        if here.type_id in self.claimed {
            skip;
        }
        self.claimed[here.type_id] = True;
        if here.type_id == self.target {
            self.found = True;
            print "reach_hit", here.type_id;
            disengage;
        }
        kids: list[SchemaType] = [];
        for ch in [here ->:Requires:->][?:SchemaType] {
            kids.append(ch);
        }
        visit kids else {
            disengage;
        }
    }
}

def build_registry(entries: list[list[str]]) -> SchemaRegistry {
    reg = SchemaRegistry(by_id={});
    root ++> reg;
    rows_copy: list[list[str]] = [];
    for row in entries {
        rows_copy.append(row);
    }
    for row in rows_copy {
        tid = row[0];
        nd = SchemaType(type_id=tid);
        root ++> nd;
        reg.by_id[tid] = nd;
    }
    for row in rows_copy {
        src_id = row[0];
        src_nd = reg.by_id[src_id] as SchemaType;
        j = 1;
        while j < len(row) {
            dst_id = row[j];
            if dst_id in reg.by_id {
                dst_nd = reg.by_id[dst_id] as SchemaType;
                src_nd +>:Requires:+> dst_nd;
            }
            j += 1;
        }
    }
    return reg;
}

def find_cycle_types(reg: SchemaRegistry) -> list[str] {
    cyclic_map: dict[str, bool] = {};
    ids: list[str] = [];
    for k in reg.by_id {
        ids.append(k);
    }
    ids = sorted(ids);
    for tid in ids {
        nd = reg.by_id[tid] as SchemaType;
        w = nd spawn CycleProbeWalker(
            claimed={}, on_path={}, path_stack=[], cycle_ids=[], origin=tid
        );
        print "cycle_probe", tid, len(w.cycle_ids);
        for ck in w.cycle_ids {
            cyclic_map[ck] = True;
        }
    }
    out: list[str] = [];
    for k in cyclic_map {
        out.append(k);
    }
    return sorted(out);
}

def requires_reachable(reg: SchemaRegistry, src: str, dst: str) -> bool {
    if src not in reg.by_id {
        return False;
    }
    if dst not in reg.by_id {
        return False;
    }
    snd = reg.by_id[src] as SchemaType;
    w = snd spawn ReachWalker(claimed={}, target=dst, found=False);
    print "requires_reachable", src, dst, w.found;
    return w.found;
}

def lazy_reference_targets(reg: SchemaRegistry) -> list[str] {
    return find_cycle_types(reg);
}
