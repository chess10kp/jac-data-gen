"""arch-hdl-lang/harc-com#483 — by-value record definition cycle detection."""

node Record {
    has name: str;
}

edge Member {}
edge Ref {}

walker FieldWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = {};

    can step with Record entry {
        print ("field_step", here.name);
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        refs: list[Record] = [here ->:Ref:->][?:Record];
        for kid in refs {
            visit :0: [kid];
        }
    }
}

walker CycleChecker {
    has gray: dict[str, bool] = {};
    has black: dict[str, bool] = {};
    has cycles: list[str] = {};
    has ok: bool = True;

    can scan_hub with Record entry {
        print ("cycle_hub", here.name);
        if here.name != "__hub__" {
            disengage;
        }
        tops: list[Record] = [here ->:Member:->][?:Record];
        for nd in tops {
            visit :0: [nd];
        }
    }

    can scan_rec with Record entry {
        print ("cycle_rec", here.name);
        if here.name == "__hub__" {
            disengage;
        }
        if here.name in self.black {
            skip;
        }
        if here.name in self.gray {
            self.ok = False;
            note: str = "by-value record cycle at " + here.name;
            self.cycles.append(note);
            skip;
        }
        self.gray[here.name] = True;
        refs: list[Record] = [here ->:Ref:->][?:Record];
        for kid in refs {
            visit :0: [kid];
        }
        self.gray[here.name] = False;
        self.black[here.name] = True;
    }
}

def build_record_graph(record_fields: dict[str, list[str]]) -> Record {
    hub = Record(name="__hub__");
    root ++> hub;
    nodes: dict[str, Record] = {};
    names: list[str] = sorted(record_fields.keys());
    for nm in names {
        nd = Record(name=nm);
        nodes[nm] = nd;
        hub +>:Member:+> nd;
    }
    for nm in names {
        src = nodes[nm];
        refs: list[str] = record_fields[nm];
        for tgt_nm in refs {
            if tgt_nm in nodes {
                dst = nodes[tgt_nm];
                src +>:Ref:+> dst;
            }
        }
    }
    return hub;
}

def node_map_for(hub: Record) -> dict[str, Record] {
    mp: dict[str, Record] = {};
    tops: list[Record] = [hub ->:Member:->][?:Record];
    for nd in tops {
        mp[nd.name] = nd;
    }
    return mp;
}

def check_no_record_cycles(record_fields: dict[str, list[str]]) -> tuple[bool, list[str]] {
    if len(record_fields) == 0 {
        return (True, []);
    }
    hub = build_record_graph(record_fields);
    w = root spawn CycleChecker();
    msgs: list[str] = sorted(w.cycles);
    return (w.ok, msgs);
}

def collect_reachable(record_fields: dict[str, list[str]], start: str) -> list[str] {
    if start not in record_fields {
        return [];
    }
    hub = build_record_graph(record_fields);
    mp = node_map_for(hub);
    st = mp[start];
    w = st spawn FieldWalk(claimed={});
    return sorted(w.order);
}

def walk_field_order(record_fields: dict[str, list[str]], start: str) -> list[str] {
    if start not in record_fields {
        return [];
    }
    hub = build_record_graph(record_fields);
    mp = node_map_for(hub);
    st = mp[start];
    w = st spawn FieldWalk(claimed={});
    return w.order;
}
