"""Provenance chain recording and verification.

camillanapoles/bioeolica-dev#14 lifted to OSP: data objects become DataObject
archetypes and record_provenance edges become typed DerivedFrom edges
carrying the transformation payload. The recursive lineage walks become
claim-mapped floods whose seen maps are the cycle policy; chain verification
checks that every trace bottoms out at a root -- an object built from
nothing -- with no dangling references.
"""
node DataObject {
    has oid: str;
}
edge DerivedFrom {
    has transformation: str;
    has params_json: str = '{}';
}

"""Ledger handle: object ids resolve through this lookup map."""
obj ProvenanceLedger {
    has objs: dict[str, DataObject];

    def resolve(oid: str) -> DataObject | None {
        return self.objs.get(oid);
    }

    def ids() -> list[str] {
        out: list[str] = [];
        for k in self.objs.keys() {
            out.append(k);
        }
        return sorted(out);
    }
}

def build_ledger() -> ProvenanceLedger {
    return ProvenanceLedger(objs={});
}

walker SourceFlood {
    # Mirrors the reference closure: the start object appears in ``reached``
    # only when a cycle brings the walk back to it.
    has claimed: dict[str, bool] = {};      # nodes already expanded
    has reported: dict[str, bool] = {};  # nodes already listed
    has reached: list[str] = [];
    has started: bool = False;

    can step with DataObject entry {
        if not self.started {
            self.started = True;
            self.claimed[here.oid] = True;
            visit [->:DerivedFrom:->];
        } else {
            if here.oid not in self.reported {
                self.reported[here.oid] = True;
                self.reached.append(here.oid);
            }
            if here.oid not in self.claimed {
                self.claimed[here.oid] = True;
                visit [->:DerivedFrom:->];
            }
        }
    }
}

walker CycleProbe {
    has target: str = "";
    has found: bool = False;
    has claimed: dict[str, bool] = {};
    has started: bool = False;

    can step with DataObject entry {
        if not self.started {
            self.started = True;
            self.claimed[here.oid] = True;
            visit [->:DerivedFrom:->];
        } else {
            if here.oid == self.target {
                self.found = True;
                disengage;
            }
            if here.oid in self.claimed {
                skip;
            }
            self.claimed[here.oid] = True;
            visit [->:DerivedFrom:->];
        }
    }
}

def _ensure_node(led: ProvenanceLedger, oid: str) -> DataObject {
    n = led.resolve(oid);
    if n is None {
        n = DataObject(oid=oid);
        root ++> n;
        led.objs[oid] = n;
    }
    return n;
}

def _direct_sources(led: ProvenanceLedger, oid: str) -> list[str] {
    n = led.resolve(oid);
    if n is None {
        return [];
    }
    outs = [n ->:DerivedFrom:->];
    names: list[str] = [];
    for t in outs {
        names.append(str(t.oid));
    }
    return names;
}

def _upstream_closure(led: ProvenanceLedger, oid: str) -> list[str] {
    st = led.resolve(oid);
    if st is None {
        return [];
    }
    w = st spawn SourceFlood();
    return w.reached;
}

def record(led: ProvenanceLedger, source_id: str, target_id: str,
           transformation: str = "copy", params_json: str = '{}') -> None {
    # Record one provenance edge source -> target (no self-edges).
    if source_id == target_id {
        raise ValueError("self-provenance edge");
    }
    src = _ensure_node(led, source_id);
    tgt = _ensure_node(led, target_id);
    # Edge points at the source: 'X derived-from Y'.
    tgt +>:DerivedFrom(transformation=transformation,
                       params_json=params_json):+> src;
}

"""All transitive sources of ``object_id`` (sorted, exclusive)."""
def get_upstream(led: ProvenanceLedger, object_id: str) -> list[str] {
    # Under a cycle an object is its own upstream; closure keeps it.
    return sorted(_upstream_closure(led, object_id));
}

"""All transitive consumers of ``object_id`` (sorted, exclusive)."""
def get_downstream(led: ProvenanceLedger, object_id: str) -> list[str] {
    # Downstream = objects whose upstream closure contains object_id.
    out: list[str] = [];
    for cand in led.ids() {
        if cand == object_id {
            continue;
        }
        w = led.objs[cand] spawn SourceFlood();
        hit = False;
        for r in w.reached {
            if r == object_id {
                hit = True;
            }
        }
        if hit {
            out.append(cand);
        }
    }
    return sorted(out);
}

"""Sorted objects lying on a provenance cycle (empty when clean)."""
def detect_cycles(led: ProvenanceLedger) -> list[str] {
    # An object lies on a cycle iff its own upstream closure returns to it.
    bad: list[str] = [];
    for oid in led.ids() {
        w = led.objs[oid] spawn CycleProbe(target=oid);
        if w.found {
            bad.append(oid);
        }
    }
    return sorted(bad);
}

def _is_root(led: ProvenanceLedger, oid: str) -> bool {
    return len(_direct_sources(led, oid)) == 0;
}

walker ChainVerify {
    """Claims the whole ancestry once; records root/dangling outcomes."""
    has ledger: ProvenanceLedger;
    has claimed: dict[str, bool] = {};
    has hit_root: bool = False;
    has hit_dangling: bool = False;

    can step with DataObject entry {
        if here.oid in self.claimed {
            skip;  # diamond revisit: already accounted for
        }
        self.claimed[here.oid] = True;
        parents = _direct_sources(self.ledger, here.oid);
        if len(parents) == 0 {
            self.hit_root = True;
            disengage;  # bottomed out at a root
        }
        for p in parents {
            if self.ledger.resolve(p) is None {
                self.hit_dangling = True;
                disengage;
            }
        }
        visit [->:DerivedFrom:->];
    }
}

"""True when every trace from ``object_id`` bottoms out at a root."""
def verify_chain(led: ProvenanceLedger, object_id: str) -> bool {
    # True when every trace bottoms out at a root, no dangling refs.
    st = led.resolve(object_id);
    if st is None {
        return False;
    }
    if len(detect_cycles(led)) > 0 {
        return False;
    }
    w = st spawn ChainVerify(ledger=led);
    return w.hit_root and not w.hit_dangling;
}
