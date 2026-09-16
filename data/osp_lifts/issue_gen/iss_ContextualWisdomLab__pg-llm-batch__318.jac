"""ContextualWisdomLab/pg-llm-batch#318 — bind batch lifecycle evidence to released Context Assertion contract."""

CATALOG_COLUMN_COUNT = 14;

node Evidence {
    has evidence_id: str;
    has column_count: int = 0;
    has catalog_ok: bool = False;
    has bound_contract: str = "";
}

node Contract {
    has contract_id: str;
    has version: str;
    has released: bool = False;
}

node ColumnSpec {
    has name: str;
    has atttypmod: int = -1;
}

edge BindsTo {}
edge Requires {}
edge Lineage {}

walker FindEvidence {
    has claimed: dict[str, bool] = {};
    has target: str;
    has hit: Evidence | None = None;

    can begin with entry {
        kids: list[object] = [];
        for ch in [here ->] { kids.append(ch); }
        visit kids;
    }

    can step with Evidence entry {
        if here.evidence_id in self.claimed { skip; }
        self.claimed[here.evidence_id] = True;
        if here.evidence_id == self.target { self.hit = here; }
        kids: list[Evidence] = [];
        for ch in [here ->:Lineage:->][?:Evidence] { kids.append(ch); }
        visit :0: kids;
    }
}

walker FindContract {
    has claimed: dict[str, bool] = {};
    has target: str;
    has hit: Contract | None = None;

    can begin with entry {
        kids: list[object] = [];
        for ch in [here ->] { kids.append(ch); }
        visit kids;
    }

    can step with Contract entry {
        if here.contract_id in self.claimed { skip; }
        self.claimed[here.contract_id] = True;
        if here.contract_id == self.target { self.hit = here; }
        kids: list[Contract] = [];
        for ch in [here ->:Lineage:->][?:Contract] { kids.append(ch); }
        visit :0: kids;
    }
}

walker ValidateCatalog {
    has claimed: dict[str, bool] = {};
    has target_id: str;
    has ok: bool = False;

    can begin with entry {
        kids: list[object] = [];
        for ch in [here ->] { kids.append(ch); }
        visit kids;
    }

    can step with Evidence entry {
        if here.evidence_id in self.claimed { skip; }
        self.claimed[here.evidence_id] = True;
        if here.evidence_id == self.target_id {
            if here.column_count == CATALOG_COLUMN_COUNT {
                cols: list[ColumnSpec] = [];
                for col in [here <-:Requires:<-][?:ColumnSpec] { cols.append(col); }
                drift: bool = False;
                for col in cols {
                    if col.atttypmod != -1 { drift = True; }
                }
                if len(cols) == CATALOG_COLUMN_COUNT and not drift {
                    self.ok = True;
                }
            }
        }
        kids: list[Evidence] = [];
        for ch in [here ->:Lineage:->][?:Evidence] { kids.append(ch); }
        visit :0: kids;
    }
}

walker CollectBindings {
    has claimed: dict[str, bool] = {};
    has contract_id: str;
    has found: list[str] = [];

    can step_contract with Contract entry {
        if here.contract_id in self.claimed { skip; }
        self.claimed[here.contract_id] = True;
        bound: list[Evidence] = [];
        for ev in [here <-:BindsTo:<-][?:Evidence] { bound.append(ev); }
        for ev in bound {
            if ev.bound_contract == self.contract_id and ev.catalog_ok {
                self.found.append(ev.evidence_id);
            }
        }
        kids: list[Contract] = [];
        for ch in [here ->:Lineage:->][?:Contract] { kids.append(ch); }
        visit :0: kids;
    }

    can step_evidence with Evidence entry {
        if here.evidence_id in self.claimed { skip; }
        self.claimed[here.evidence_id] = True;
        if here.bound_contract == self.contract_id and here.catalog_ok {
            self.found.append(here.evidence_id);
        }
        kids: list[Evidence] = [];
        for ch in [here ->:Lineage:->][?:Evidence] { kids.append(ch); }
        visit :0: kids;
    }
}

walker ReconcileLifecycle {
    has claimed: dict[str, bool] = {};
    has contract_id: str;
    has reconciled: list[str] = [];

    can step_contract with Contract entry {
        if here.contract_id in self.claimed { skip; }
        self.claimed[here.contract_id] = True;
        if here.contract_id == self.contract_id and here.released {
            bound: list[Evidence] = [];
            for ev in [here <-:BindsTo:<-][?:Evidence] { bound.append(ev); }
            for ev in bound {
                if ev.catalog_ok {
                    self.reconciled.append(ev.evidence_id);
                }
            }
        }
        kids: list[Contract] = [];
        for ch in [here ->:Lineage:->][?:Contract] { kids.append(ch); }
        visit :0: kids;
    }

    can step_evidence with Evidence entry {
        if here.evidence_id in self.claimed { skip; }
        self.claimed[here.evidence_id] = True;
        kids: list[Evidence] = [];
        for ch in [here ->:Lineage:->][?:Evidence] { kids.append(ch); }
        visit :0: kids;
    }
}

def bind_batch_evidence(graph_root: object, evidence_id: str, contract_id: str) -> dict[str, str] {
    _ = graph_root;
    ew = root spawn FindEvidence(claimed={}, target=evidence_id);
    cw = root spawn FindContract(claimed={}, target=contract_id);
    ev = ew.hit;
    ct = cw.hit;
    if ev is None or ct is None {
        return {"status": "unknown", "evidence_id": evidence_id, "contract_id": contract_id};
    }
    if not ct.released {
        return {"status": "not_released", "evidence_id": evidence_id, "contract_id": contract_id};
    }
    ev.bound_contract = contract_id;
    ev.catalog_ok = ev.column_count == CATALOG_COLUMN_COUNT;
    ct +>:BindsTo:+> ev;
    return {"status": "bound", "evidence_id": evidence_id, "contract_id": contract_id};
}

def validate_catalog(graph_root: object, evidence_id: str) -> bool {
    _ = graph_root;
    w = root spawn ValidateCatalog(claimed={}, target_id=evidence_id);
    print(w.ok);
    return w.ok;
}

def collect_bindings(graph_root: object, contract_id: str) -> list[str] {
    _ = graph_root;
    cw = root spawn FindContract(claimed={}, target=contract_id);
    ct = cw.hit;
    if ct is None {
        print([]);
        return [];
    }
    w = ct spawn CollectBindings(claimed={}, contract_id=contract_id);
    out: list[str] = w.found;
    out.sort();
    print(out);
    return out;
}

def reconcile_lifecycle(graph_root: object, contract_id: str) -> list[str] {
    _ = graph_root;
    cw = root spawn FindContract(claimed={}, target=contract_id);
    ct = cw.hit;
    if ct is None {
        print([]);
        return [];
    }
    w = ct spawn ReconcileLifecycle(claimed={}, contract_id=contract_id);
    out: list[str] = w.reconciled;
    out.sort();
    print(out);
    return out;
}

with entry {
    ct0 = Contract(contract_id="demo-c", version="1", released=True);
    ev0 = Evidence(evidence_id="demo-e", column_count=14);
    root ++> ct0;
    root ++> ev0;
    bind_batch_evidence(root, "demo-e", "demo-c");
    validate_catalog(root, "demo-e");
    collect_bindings(root, "demo-c");
    reconcile_lifecycle(root, "demo-c");
}
