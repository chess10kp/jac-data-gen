"""ShippedLabs/soroban-upgrade-safeguard#431 — mutually recursive UDT refs overflow compare walks."""

node Udt {
    has name: str;
}

edge RefsTo {}

obj ContractSpec {
    has udt_fields: dict[str, list[str]] = {};
    has functions: dict[str, list[str]] = {};
    has events: dict[str, list[str]] = {};
    has udts: dict[str, Udt] = {};
}

walker ExtractUdtsWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Udt entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        kids = [here ->:RefsTo:->][?:Udt];
        nms: list[str] = [];
        for k in kids { nms.append(k.name); }
        for nm in sorted(nms) {
            for k in kids {
                if k.name == nm and k.name not in self.claimed { visit [k]; }
            }
        }
    }
}

walker RefsTypeWalk {
    has target: str = "";
    has claimed: dict[str, bool] = {};
    has hit: bool = False;
    has udt_fields: dict[str, list[str]] = {};

    can step with Udt entry {
        if self.hit { skip; }
        if here.name == self.target {
            self.hit = True;
            skip;
        }
        fields = self.udt_fields.get(here.name, []);
        for ref in fields {
            if ref == self.target {
                self.hit = True;
                skip;
            }
        }
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        kids = [here ->:RefsTo:->][?:Udt];
        nms: list[str] = [];
        for k in kids { nms.append(k.name); }
        for nm in sorted(nms) {
            for k in kids {
                if k.name == nm and k.name != here.name and k.name not in self.claimed {
                    visit [k];
                }
            }
        }
    }
}

walker CascadeWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Udt entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        parents = [here <-:RefsTo:<-][?:Udt];
        nms: list[str] = [];
        for p in parents { nms.append(p.name); }
        for nm in sorted(nms) {
            for p in parents {
                if p.name == nm and p.name not in self.claimed { visit [p]; }
            }
        }
    }
}

def _clear_spec_graph {
    live = [root -->][?:Udt];
    for nd in live { del nd; }
}

def _attach_spec_graph(spec: ContractSpec) {
    for (name, fields) in spec.udt_fields.items() {
        nd = Udt(name=name);
        root ++> nd;
        spec.udts[name] = nd;
    }
    for (name, fields) in spec.udt_fields.items() {
        src = spec.udts.get(name, None);
        if src is None { continue; }
        for ref in fields {
            tgt = spec.udts.get(ref, None);
            if tgt is not None { src +>:RefsTo:+> tgt; }
        }
    }
}

def load_spec(
    udt_fields: dict[str, list[str]],
    functions: dict[str, list[str]] | None = None,
    events: dict[str, list[str]] | None = None,
) -> ContractSpec {
    _clear_spec_graph();
    spec = ContractSpec();
    uf: dict[str, list[str]] = {};
    for (k, v) in udt_fields.items() {
        row: list[str] = [];
        for x in v { row.append(x); }
        uf[k] = row;
    }
    spec.udt_fields = uf;
    fn: dict[str, list[str]] = {};
    raw_fn = functions if functions is not None else {};
    for (k, v) in raw_fn.items() {
        row2: list[str] = [];
        for x in v { row2.append(x); }
        fn[k] = row2;
    }
    spec.functions = fn;
    ev: dict[str, list[str]] = {};
    raw_ev = events if events is not None else {};
    for (k, v) in raw_ev.items() {
        row3: list[str] = [];
        for x in v { row3.append(x); }
        ev[k] = row3;
    }
    spec.events = ev;
    _attach_spec_graph(spec);
    return spec;
}

def extract_udts(spec: ContractSpec, `root: str) -> list[str] {
    if `root not in spec.udt_fields { return [`root]; }
    nd = spec.udts.get(`root, None);
    if nd is None { return [`root]; }
    w = nd spawn ExtractUdtsWalk(claimed={}, found=[]);
    return sorted(w.found);
}

def references_type(spec: ContractSpec, from_type: str, target: str) -> bool {
    if from_type not in spec.udt_fields { return from_type == target; }
    nd = spec.udts.get(from_type, None);
    if nd is None { return from_type == target; }
    w = nd spawn RefsTypeWalk(
        target=target,
        claimed={},
        hit=False,
        udt_fields=spec.udt_fields,
    );
    return w.hit;
}

def is_type_used_in_functions(spec: ContractSpec, type_name: str) -> bool {
    for params in spec.functions.values() {
        for param in params {
            if param == type_name or references_type(spec, param, type_name) {
                return True;
            }
        }
    }
    return False;
}

def is_type_used_in_events(spec: ContractSpec, type_name: str) -> bool {
    for fields in spec.events.values() {
        for field_type in fields {
            if field_type == type_name or references_type(spec, field_type, type_name) {
                return True;
            }
        }
    }
    return False;
}

def detect_cascading_layout_breaks(
    spec: ContractSpec, changed: list[str]
) -> list[str] {
    cascaded: dict[str, bool] = {};
    for c in changed {
        nd = spec.udts.get(c, None);
        if nd is not None {
            w = nd spawn CascadeWalk(claimed={}, found=[]);
            for n in w.found { cascaded[n] = True; }
        } else {
            cascaded[c] = True;
        }
    }
    out: list[str] = [];
    for k in cascaded.keys() { out.append(k); }
    return sorted(out);
}

def classify_finding_axes(spec: ContractSpec, finding_type: str) -> list[str] {
    axes: list[str] = [];
    if is_type_used_in_functions(spec, finding_type) {
        axes.append("function_usage");
    }
    if is_type_used_in_events(spec, finding_type) {
        axes.append("event_usage");
    }
    cascade = detect_cascading_layout_breaks(spec, [finding_type]);
    for x in cascade {
        if x == finding_type { axes.append("layout_cascade"); }
    }
    return sorted(axes);
}
