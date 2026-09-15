"""Schema extends composition — NodeSpaceAI/nodespace-core#2598."""

node Schema {
    has sid: str;
    has own_fields: dict[str, str] = {};
}

edge Extends {}

walker CycleCheck {
    has child_id: str;
    has found_cycle: bool = False;
    has claimed: dict[str, bool] = {};
    can step with Schema entry {
        if here.sid == self.child_id {
            self.found_cycle = True;
            disengage;
        }
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        ups: list[Schema] = [here ->:Extends:->][?:Schema];
        for u in ups {
            visit u;
        }
        downs: list[Schema] = [here <-:Extends:][?:Schema];
        for d in downs {
            visit d;
        }
        disengage;
    }
}

walker ResolveWalker {
    has claimed: dict[str, bool] = {};
    has lineage: list[str] = [];
    can step with Schema entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        self.lineage.append(here.sid);
        parents: list[Schema] = [here ->:Extends:->][?:Schema];
        for p in parents {
            visit :0: [p];
        }
        disengage;
    }
}

walker SchemaFinder {
    has target: str;
    has found: Schema | None = None;
    has claimed: dict[str, bool] = {};
    can start with entry {
        seeds: list[Schema] = [root ->][?:Schema];
        for s in seeds {
            visit s;
        }
        disengage;
    }
    can step with Schema entry {
        if here.sid == self.target {
            self.found = here;
            disengage;
        }
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        kids: list[Schema] = [here->][?:Schema];
        for k in kids {
            visit k;
        }
        disengage;
    }
}

walker DemoWalker {
    has claimed: dict[str, bool] = {};
    can start with entry {
        seeds: list[Schema] = [root ->][?:Schema];
        for s in seeds {
            visit s;
        }
        disengage;
    }
    can show with Schema entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        eff = resolve_effective_fields(root, here.sid);
        print("schema", here.sid, "fields", eff);
        kids: list[Schema] = [here->][?:Schema];
        for k in kids {
            visit k;
        }
        disengage;
    }
}

def find_schema(graph_root: object, schema_id: str) -> Schema | None {
    w = graph_root spawn SchemaFinder(target=schema_id);
    return w.found;
}

def fields_conflict(own: dict[str, str], inherited: dict[str, str]) -> bool {
    keys = sorted(own);
    for k in keys {
        if k in inherited {
            return True;
        }
    }
    return False;
}

def would_create_extends_cycle(graph_root: object, child_id: str, parent_id: str) -> bool {
    if child_id == parent_id {
        return True;
    }
    parent = find_schema(graph_root, parent_id);
    if parent is None {
        return False;
    }
    wk = parent spawn CycleCheck(child_id=child_id);
    return wk.found_cycle;
}

def resolve_effective_fields(graph_root: object, schema_id: str) -> dict[str, str] {
    sch = find_schema(graph_root, schema_id);
    result: dict[str, str] = {};
    if sch is None {
        return result;
    }
    wk = sch spawn ResolveWalker;
    idx = len(wk.lineage) - 1;
    while idx >= 0 {
        lid = wk.lineage[idx];
        schema_nd = find_schema(graph_root, lid);
        if schema_nd is not None {
            keys = sorted(schema_nd.own_fields);
            for k in keys {
                result[k] = schema_nd.own_fields[k];
            }
        }
        idx -= 1;
    }
    return result;
}

def declare_extends(graph_root: object, child_id: str, parent_id: str) -> bool {
    child = find_schema(graph_root, child_id);
    parent = find_schema(graph_root, parent_id);
    if child is None or parent is None {
        return False;
    }
    existing: list[Schema] = [child ->:Extends:->][?:Schema];
    if len(existing) > 0 {
        return False;
    }
    if would_create_extends_cycle(graph_root, child_id, parent_id) {
        return False;
    }
    inherited = resolve_effective_fields(graph_root, parent_id);
    if fields_conflict(child.own_fields, inherited) {
        return False;
    }
    child +>:Extends:+> parent;
    return True;
}

def create_schema(
    graph_root: object,
    schema_id: str,
    own_fields: dict[str, str],
    extends_id: str | None = None
) -> bool {
    if find_schema(graph_root, schema_id) is not None {
        return False;
    }
    parent_key: str = "";
    if extends_id is not None {
        parent_key = extends_id;
    }
    if parent_key != "" {
        if find_schema(graph_root, parent_key) is None {
            return False;
        }
        if would_create_extends_cycle(graph_root, schema_id, parent_key) {
            return False;
        }
        inherited = resolve_effective_fields(graph_root, parent_key);
        if fields_conflict(own_fields, inherited) {
            return False;
        }
    }
    nd = Schema(sid=schema_id, own_fields=own_fields);
    graph_root ++> nd;
    if parent_key != "" {
        par = find_schema(graph_root, parent_key);
        if par is not None {
            nd +>:Extends:+> par;
        }
    }
    return True;
}

with entry {
    root spawn DemoWalker;
}
