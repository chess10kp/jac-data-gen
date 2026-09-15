"""jdorn/json-editor#764 — self-referential JSON Schema $ref graphs."""

node Def {
    has def_id: str;
    has title: str = "";
    has prop_map: dict[str, str] = {};
    has pattern_map: dict[str, str] = {};
    has one_of_ids: list[str] = [];
    has items_id: str = "";
}

edge Ref {}
edge Prop {
    has key: str;
    has is_pattern: bool = False;
}
edge OneOf {}
edge Items {}

walker RefClosureWalker {
    has claimed: dict[str, bool] = {};
    has registry: dict[str, object] = {};
    has target_id: str = "";
    has found: list[str] = [];

    can launch entry {
        print ["ref_closure", self.target_id];
        if self.target_id in self.registry {
            visit [self.registry[self.target_id] as Def];
        } else {
            disengage;
        }
    }

    can traverse with Def entry {
        if here.def_id in self.claimed {
            skip;
        }
        self.claimed[here.def_id] = True;
        self.found.append(here.def_id);
        nexts: list[Def] = [];
        for ch in [here ->:Ref:->][?:Def] {
            nexts.append(ch);
        }
        for ch in [here ->:OneOf:->][?:Def] {
            nexts.append(ch);
        }
        for ch in [here ->:Items:->][?:Def] {
            nexts.append(ch);
        }
        for pk in here.prop_map {
            tid = here.prop_map[pk] as str;
            if tid in self.registry {
                nexts.append(self.registry[tid] as Def);
            }
        }
        for pk in here.pattern_map {
            tid = here.pattern_map[pk] as str;
            if tid in self.registry {
                nexts.append(self.registry[tid] as Def);
            }
        }
        if nexts {
            visit :0: nexts;
        } else {
            disengage;
        }
    }
}

walker CycleProbeWalker {
    has registry: dict[str, object] = {};
    has target_id: str = "";
    has stack: list[str] = [];
    has cycle: list[str] = [];

    can launch entry {
        print ["cycle_probe", self.target_id];
        if self.target_id in self.registry {
            visit [self.registry[self.target_id] as Def];
        } else {
            disengage;
        }
    }

    can walk with Def entry {
        if here.def_id in self.stack {
            start_idx = 0;
            for i in range(len(self.stack)) {
                if self.stack[i] == here.def_id {
                    start_idx = i;
                    break;
                }
            }
            self.cycle = [];
            for j in range(start_idx, len(self.stack)) {
                self.cycle.append(self.stack[j]);
            }
            self.cycle.append(here.def_id);
            disengage;
        }
        self.stack.append(here.def_id);
        ref_next: list[Def] = [];
        for ch in [here ->:Ref:->][?:Def] {
            ref_next.append(ch);
        }
        if ref_next {
            visit :0: ref_next;
        } else {
            disengage;
        }
    }
}

walker ExportWalker {
    has claimed: dict[str, bool] = {};
    has registry: dict[str, object] = {};
    has target_id: str = "";
    has max_depth: int = 3;
    has doc: dict = {};

    can launch entry {
        print ["safe_export", self.target_id];
        self.doc = materialize(self.registry, self.target_id, self.claimed, self.max_depth, 0);
        disengage;
    }
}

walker ReactionWalker {
    has claimed: dict[str, bool] = {};
    has registry: dict[str, object] = {};
    has target_id: str = "";
    has keys: list[str] = [];

    can launch entry {
        print ["reaction_keys", self.target_id];
        if self.target_id in self.registry {
            visit [self.registry[self.target_id] as Def];
        } else {
            disengage;
        }
    }

    can traverse with Def entry {
        if here.def_id in self.claimed {
            skip;
        }
        self.claimed[here.def_id] = True;
        for pk in here.prop_map {
            self.keys.append(pk as str);
        }
        for pk in here.pattern_map {
            pat: str = "^" + (pk as str);
            self.keys.append(pat);
        }
        if here.items_id != "" {
            self.keys.append("items");
        }
        if len(here.one_of_ids) > 0 {
            self.keys.append("oneOf");
        }
        nexts: list[Def] = [];
        for ch in [here ->:Ref:->][?:Def] {
            nexts.append(ch);
        }
        for ch in [here ->:OneOf:->][?:Def] {
            nexts.append(ch);
        }
        for ch in [here ->:Items:->][?:Def] {
            nexts.append(ch);
        }
        for pk in here.prop_map {
            tid = here.prop_map[pk] as str;
            if tid in self.registry {
                nexts.append(self.registry[tid] as Def);
            }
        }
        for pk in here.pattern_map {
            tid = here.pattern_map[pk] as str;
            if tid in self.registry {
                nexts.append(self.registry[tid] as Def);
            }
        }
        if nexts {
            visit :0: nexts;
        } else {
            disengage;
        }
    }
}

def build_registry(specs: dict[str, dict]) -> dict[str, object] {
    nodes: dict[str, object] = {};
    for def_id in specs {
        spec = specs[def_id] as dict;
        title_val = "";
        if "title" in spec {
            title_val = spec["title"] as str;
        }
        nd = Def(def_id=def_id as str, title=title_val);
        root ++> nd;
        nodes[def_id as str] = nd;
    }
    for def_id in specs {
        spec = specs[def_id] as dict;
        src = nodes[def_id as str] as Def;
        if "ref_edges" in spec {
            rlist = spec["ref_edges"] as list;
            for rid in rlist {
                rid_s = rid as str;
                if rid_s in nodes {
                    src +>:Ref:+> (nodes[rid_s] as Def);
                }
            }
        }
        if "properties" in spec {
            pmap = spec["properties"] as dict;
            for pk in pmap {
                pk_s = pk as str;
                tv = pmap[pk];
                if tv is not None {
                    tid = tv as str;
                    if tid in nodes {
                        src.prop_map[pk_s] = tid;
                        src +>:Prop(key=pk_s, is_pattern=False):+> (nodes[tid] as Def);
                    }
                }
            }
        }
        if "patternProperties" in spec {
            ppmap = spec["patternProperties"] as dict;
            for pk in ppmap {
                pk_s = pk as str;
                tv = ppmap[pk];
                if tv is not None {
                    tid = tv as str;
                    if tid in nodes {
                        src.pattern_map[pk_s] = tid;
                        src +>:Prop(key=pk_s, is_pattern=True):+> (nodes[tid] as Def);
                    }
                }
            }
        }
        if "oneOf" in spec {
            olist = spec["oneOf"] as list;
            for oid in olist {
                oid_s = oid as str;
                if oid_s in nodes {
                    src.one_of_ids.append(oid_s);
                    src +>:OneOf:+> (nodes[oid_s] as Def);
                }
            }
        }
        if "items" in spec {
            iv = spec["items"];
            if iv is not None {
                iid = iv as str;
                if iid in nodes {
                    src.items_id = iid;
                    src +>:Items:+> (nodes[iid] as Def);
                }
            }
        }
    }
    return nodes;
}

def materialize(
    registry: dict[str, object],
    start: str,
    claimed: dict[str, bool],
    max_depth: int,
    depth: int
) -> dict[str, object] {
    if not (start in registry) {
        return {};
    }
    if depth > max_depth {
        return {"$ref": start};
    }
    if start in claimed {
        return {"$ref": start};
    }
    claimed[start] = True;
    nd = registry[start] as Def;
    out: dict[str, object] = {};
    if nd.title != "" {
        out["title"] = nd.title;
    }
    ref_targets: list[Def] = [];
    for ch in [nd ->:Ref:->][?:Def] {
        ref_targets.append(ch);
    }
    if ref_targets {
        out["$ref"] = ref_targets[0].def_id;
        claimed[start] = False;
        return out;
    }
    props: dict[str, object] = {};
    for pk in nd.prop_map {
        pk_s = pk as str;
        tid = nd.prop_map[pk] as str;
        props[pk_s] = materialize(registry, tid, claimed, max_depth, depth + 1);
    }
    if props {
        out["properties"] = props;
    }
    ppats: dict[str, object] = {};
    for pk in nd.pattern_map {
        pk_s = pk as str;
        tid = nd.pattern_map[pk] as str;
        ppats[pk_s] = materialize(registry, tid, claimed, max_depth, depth + 1);
    }
    if ppats {
        out["patternProperties"] = ppats;
    }
    if nd.items_id != "" {
        out["items"] = materialize(registry, nd.items_id, claimed, max_depth, depth + 1);
    }
    if len(nd.one_of_ids) > 0 {
        olist: list[object] = [];
        for oid in nd.one_of_ids {
            olist.append(materialize(registry, oid, claimed, max_depth, depth + 1));
        }
        out["oneOf"] = olist;
    }
    claimed[start] = False;
    return out;
}

def ref_closure(registry: dict[str, object], start_id: str) -> list[str] {
    if not (start_id in registry) {
        return [];
    }
    w = (registry[start_id] as Def) spawn RefClosureWalker(
        registry=registry,
        target_id=start_id
    );
    found: list[str] = [];
    for x in w.found {
        found.append(x as str);
    }
    found.sort();
    return found;
}

def detect_cycle(registry: dict[str, object], start_id: str) -> list[str] {
    if not (start_id in registry) {
        return [];
    }
    w = (registry[start_id] as Def) spawn CycleProbeWalker(
        registry=registry,
        target_id=start_id
    );
    return w.cycle;
}

def safe_export(registry: dict[str, object], start_id: str, max_depth: int = 3) -> dict[str, object] {
    if not (start_id in registry) {
        return {};
    }
    w = (registry[start_id] as Def) spawn ExportWalker(
        registry=registry,
        target_id=start_id,
        max_depth=max_depth
    );
    return w.doc;
}

def reaction_keys(registry: dict[str, object], start_id: str) -> list[str] {
    if not (start_id in registry) {
        return [];
    }
    w = (registry[start_id] as Def) spawn ReactionWalker(
        registry=registry,
        target_id=start_id
    );
    keys: list[str] = [];
    for k in w.keys {
        keys.append(k as str);
    }
    keys.sort();
    return keys;
}
