"""Batch lifecycle evidence binding — ContextualWisdomLab/pg-llm-batch#318."""

node Batch {
    has bid: str;
    has contract: str = "";
}

node Evidence {
    has eid: str;
    has bound: bool = False;
}

node ColumnSpec {
    has name: str;
    has atttypmod: int = -1;
    has not_null: bool = True;
}

edge Requires {}
edge Binds {}
edge Proves {}

glob CANONICAL_COLUMNS = [
    "evidence_id", "batch_id", "tenant_id", "created_at",
    "updated_at", "status", "payload_hash", "outbox_seq",
    "replay_token", "rls_role", "contract_ref", "audit_id",
    "recovery_flag", "atttypmod_probe"
];

def column_index(name: str) -> int {
    i = 0;
    for col in CANONICAL_COLUMNS {
        if col == name {
            return i;
        }
        i += 1;
    }
    return -1;
}

def contains_str(xs: list[str], key: str) -> bool {
    for x in xs {
        if x == key {
            return True;
        }
    }
    return False;
}

def probe_column_authority(specs: list[ColumnSpec]) -> bool {
    if len(specs) != 14 {
        return False;
    }
    seen: dict[str, bool] = {};
    for sp in specs {
        if column_index(sp.name) < 0 {
            return False;
        }
        if sp.name in seen {
            return False;
        }
        seen[sp.name] = True;
        if sp.atttypmod != -1 {
            return False;
        }
    }
    for col in CANONICAL_COLUMNS {
        if col not in seen {
            return False;
        }
    }
    return True;
}

def list_drift_violations(specs: list[ColumnSpec]) -> list[str] {
    violations: list[str] = [];
    present: dict[str, bool] = {};
    for sp in specs {
        present[sp.name] = True;
        if column_index(sp.name) < 0 {
            violations.append("extra:" + sp.name);
        } elif sp.atttypmod != -1 {
            violations.append("typmod:" + sp.name);
        }
    }
    for col in CANONICAL_COLUMNS {
        if col not in present {
            violations.append("missing:" + col);
        }
    }
    return sorted(violations);
}

walker BindEvidence {
    has claimed: dict[str, bool] = {};
    has contract_version: str = "";
    has bound_ids: list[str] = [];

    can step_batch with Batch entry {
        if here.bid in self.claimed {
            skip;
        }
        self.claimed[here.bid] = True;
        print("bind " + here.bid);
        evs: list[Evidence] = [here ->:Binds:->][?:Evidence];
        for ev in evs {
            if self.contract_version != "" {
                ev.bound = True;
            }
            if not contains_str(self.bound_ids, ev.eid) {
                self.bound_ids.append(ev.eid);
            }
        }
        kids: list[Batch] = [here ->:Requires:->][?:Batch];
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker ReconcileChain {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step_ev with Evidence entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        print("reconcile " + here.eid);
        self.chain.append(here.eid);
        kids: list[Evidence] = [here ->:Proves:->][?:Evidence];
        visit :0: kids;
    }
}

def make_canonical_specs() -> list[ColumnSpec] {
    out: list[ColumnSpec] = [];
    for col in CANONICAL_COLUMNS {
        sp = ColumnSpec(name=col, atttypmod=-1, not_null=True);
        out.append(sp);
    }
    return out;
}

def build_batch_diamond() -> Batch {
    rb = Batch(bid="b-root");
    ma = Batch(bid="b-a");
    mb = Batch(bid="b-b");
    jn = Batch(bid="b-join");
    e1 = Evidence(eid="ev-1");
    e2 = Evidence(eid="ev-2");
    e3 = Evidence(eid="ev-3");
    root ++> rb;
    rb +>:Requires:+> ma;
    rb +>:Requires:+> mb;
    ma +>:Requires:+> jn;
    mb +>:Requires:+> jn;
    jn +>:Binds:+> e1;
    jn +>:Binds:+> e2;
    rb +>:Binds:+> e3;
    return rb;
}

def build_evidence_diamond() -> Evidence {
    er = Evidence(eid="ev-r");
    ea = Evidence(eid="ev-a");
    eb = Evidence(eid="ev-b");
    ej = Evidence(eid="ev-j");
    root ++> er;
    er +>:Proves:+> ea;
    er +>:Proves:+> eb;
    ea +>:Proves:+> ej;
    eb +>:Proves:+> ej;
    return er;
}

def bind_lifecycle_evidence(graph_root: Batch, contract_version: str) -> list[str] {
    w = graph_root spawn BindEvidence(claimed={}, contract_version=contract_version);
    return sorted(w.bound_ids);
}

def reconcile_evidence_chain(graph_root: Evidence) -> list[str] {
    w = graph_root spawn ReconcileChain(claimed={});
    return w.chain;
}

"""Batch lifecycle evidence binding — ContextualWisdomLab/pg-llm-batch#318."""

node Batch {
    has bid: str;
    has contract: str = "";
}

node Evidence {
    has eid: str;
    has bound: bool = False;
}

node ColumnSpec {
    has name: str;
    has atttypmod: int = -1;
    has not_null: bool = True;
}

edge Requires {}
edge Binds {}
edge Proves {}

glob CANONICAL_COLUMNS = [
    "evidence_id", "batch_id", "tenant_id", "created_at",
    "updated_at", "status", "payload_hash", "outbox_seq",
    "replay_token", "rls_role", "contract_ref", "audit_id",
    "recovery_flag", "atttypmod_probe"
];

def column_index(name: str) -> int {
    i = 0;
    for col in CANONICAL_COLUMNS {
        if col == name {
            return i;
        }
        i += 1;
    }
    return -1;
}

def contains_str(xs: list[str], key: str) -> bool {
    for x in xs {
        if x == key {
            return True;
        }
    }
    return False;
}

def probe_column_authority(specs: list[ColumnSpec]) -> bool {
    if len(specs) != 14 {
        return False;
    }
    seen: dict[str, bool] = {};
    for sp in specs {
        if column_index(sp.name) < 0 {
            return False;
        }
        if sp.name in seen {
            return False;
        }
        seen[sp.name] = True;
        if sp.atttypmod != -1 {
            return False;
        }
    }
    for col in CANONICAL_COLUMNS {
        if col not in seen {
            return False;
        }
    }
    return True;
}

def list_drift_violations(specs: list[ColumnSpec]) -> list[str] {
    violations: list[str] = [];
    present: dict[str, bool] = {};
    for sp in specs {
        present[sp.name] = True;
        if column_index(sp.name) < 0 {
            violations.append("extra:" + sp.name);
        } elif sp.atttypmod != -1 {
            violations.append("typmod:" + sp.name);
        }
    }
    for col in CANONICAL_COLUMNS {
        if col not in present {
            violations.append("missing:" + col);
        }
    }
    return sorted(violations);
}

walker BindEvidence {
    has claimed: dict[str, bool] = {};
    has contract_version: str = "";
    has bound_ids: list[str] = [];

    can step_batch with Batch entry {
        if here.bid in self.claimed {
            skip;
        }
        self.claimed[here.bid] = True;
        print("bind " + here.bid);
        evs: list[Evidence] = [here ->:Binds:->][?:Evidence];
        for ev in evs {
            if self.contract_version != "" {
                ev.bound = True;
            }
            if not contains_str(self.bound_ids, ev.eid) {
                self.bound_ids.append(ev.eid);
            }
        }
        kids: list[Batch] = [here ->:Requires:->][?:Batch];
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker ReconcileChain {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step_ev with Evidence entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        print("reconcile " + here.eid);
        self.chain.append(here.eid);
        kids: list[Evidence] = [here ->:Proves:->][?:Evidence];
        visit :0: kids;
    }
}

def make_canonical_specs() -> list[ColumnSpec] {
    out: list[ColumnSpec] = [];
    for col in CANONICAL_COLUMNS {
        sp = ColumnSpec(name=col, atttypmod=-1, not_null=True);
        out.append(sp);
    }
    return out;
}

def build_batch_diamond() -> Batch {
    rb = Batch(bid="b-root");
    ma = Batch(bid="b-a");
    mb = Batch(bid="b-b");
    jn = Batch(bid="b-join");
    e1 = Evidence(eid="ev-1");
    e2 = Evidence(eid="ev-2");
    e3 = Evidence(eid="ev-3");
    root ++> rb;
    rb +>:Requires:+> ma;
    rb +>:Requires:+> mb;
    ma +>:Requires:+> jn;
    mb +>:Requires:+> jn;
    jn +>:Binds:+> e1;
    jn +>:Binds:+> e2;
    rb +>:Binds:+> e3;
    return rb;
}

def build_evidence_diamond() -> Evidence {
    er = Evidence(eid="ev-r");
    ea = Evidence(eid="ev-a");
    eb = Evidence(eid="ev-b");
    ej = Evidence(eid="ev-j");
    root ++> er;
    er +>:Proves:+> ea;
    er +>:Proves:+> eb;
    ea +>:Proves:+> ej;
    eb +>:Proves:+> ej;
    return er;
}

def bind_lifecycle_evidence(graph_root: Batch, contract_version: str) -> list[str] {
    w = graph_root spawn BindEvidence(claimed={}, contract_version=contract_version);
    return sorted(w.bound_ids);
}

def reconcile_evidence_chain(graph_root: Evidence) -> list[str] {
    w = graph_root spawn ReconcileChain(claimed={});
    return w.chain;
}

test "probe_column_authority_canonical" {
    specs = make_canonical_specs();
    assert probe_column_authority(specs);
}

test "list_drift_violations_sorted" {
    specs = make_canonical_specs();
    bad = ColumnSpec(name="bogus", atttypmod=-1, not_null=True);
    specs.append(bad);
    violations = list_drift_violations(specs);
    assert violations == sorted(["extra:bogus"]);
}

test "bind_lifecycle_evidence_contract" {
    rb = build_batch_diamond();
    ids = bind_lifecycle_evidence(rb, "ctx-assert-v1");
    assert ids == ["ev-1", "ev-2", "ev-3"];
    evs: list[Evidence] = [rb ->>:Binds:->][?:Evidence];
    for ev in evs {
        if ev.eid == "ev-3" {
            assert ev.bound;
        }
    }
}

test "bind_lifecycle_evidence_empty_contract" {
    rb = build_batch_diamond();
    ids = bind_lifecycle_evidence(rb, "");
    assert ids == ["ev-1", "ev-2", "ev-3"];
}

test "reconcile_evidence_chain_linear" {
    er = Evidence(eid="ev-r");
    ea = Evidence(eid="ev-a");
    root ++> er;
    er +>:Proves:+> ea;
    chain = reconcile_evidence_chain(er);
    assert chain == ["ev-r", "ev-a"];
}

test "reconcile_adversarial_diamond_order" {
    er = build_evidence_diamond();
    chain = reconcile_evidence_chain(er);
    assert chain == ["ev-r", "ev-a", "ev-j", "ev-b"];
    assert len(chain) == 4;
}
