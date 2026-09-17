"""Bind batch lifecycle evidence to a released Context Assertion contract.
ContextualWisdomLab/pg-llm-batch#318
"""

node CatalogTable {
    has cid: str;
    has name: str;
    has admitted: bool = False;
}

node Column {
    has cid: str;
    has name: str;
    has atttypmod: int = -1;
}

node BatchEvidence {
    has cid: str;
    has batch_id: str;
    has evidence_id: str = "";
    has bound: bool = False;
}

node ContractAssertion {
    has cid: str;
    has ref: str;
    has version: str;
    has released: bool = False;
}

edge Cascade {}
edge Catalog {}
edge EvidenceBind {}

walker AuthorityWalker {
    has table_cid: str = "";
    has claimed: dict[str, bool] = {};
    has rejected: list[str] = [];

    can probe_table with CatalogTable entry {
        if here.cid != self.table_cid {
            skip;
        }
        print ["authority_probe", here.name];
        cols: list[Column] = [here ->:Catalog:->][?:Column];
        for col in cols {
            visit :0: [col];
        }
        disengage;
    }

    can probe_column with Column entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ["column_probe", here.name, here.atttypmod];
        if here.atttypmod != -1 {
            self.rejected.append(here.name);
        }
        kids: list[Column] = [here ->:Cascade:->][?:Column];
        for kid in kids {
            visit :0: [kid];
        }
        disengage;
    }
}

walker CollectBindWalker {
    has batch_id: str = "";
    has evidence_id: str = "";
    has contract_ref: str = "";
    has claimed: dict[str, bool] = {};
    has evidence: BatchEvidence | None = None;
    has contract: ContractAssertion | None = None;

    can probe_root with CatalogTable entry {
        print ["bind_collect", here.cid];
        evs: list[BatchEvidence] = [here -->][?:BatchEvidence];
        for ev in evs {
            visit [ev];
        }
        cts: list[ContractAssertion] = [here -->][?:ContractAssertion];
        for ct in cts {
            visit [ct];
        }
        disengage;
    }

    can probe_evidence with BatchEvidence entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ["bind_evidence", here.batch_id, here.evidence_id];
        if here.batch_id == self.batch_id {
            if self.evidence_id == "" or here.evidence_id == "" or here.evidence_id == self.evidence_id {
                self.evidence = here;
            }
        }
        disengage;
    }

    can probe_contract with ContractAssertion entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ["bind_contract", here.ref, here.released];
        if here.ref == self.contract_ref and here.released {
            self.contract = here;
        }
        disengage;
    }
}

def _resolve_table(graph_root: CatalogTable, table_cid: str) -> CatalogTable | None {
    if graph_root.cid == table_cid {
        return graph_root;
    }
    return None;
}

def verify_column_cascade(graph_root: CatalogTable, table_cid: str) -> list[str] {
    w = graph_root spawn AuthorityWalker(table_cid=table_cid);
    out: list[str] = w.rejected;
    return sorted(out);
}

def bind_evidence_to_contract(
    graph_root: CatalogTable,
    batch_id: str,
    evidence_id: str,
    contract_ref: str
) -> dict[str, object] {
    w = graph_root spawn CollectBindWalker(
        batch_id=batch_id,
        evidence_id=evidence_id,
        contract_ref=contract_ref
    );
    result: dict[str, object] = {};
    result["batch_id"] = batch_id;
    result["evidence_id"] = evidence_id;
    result["contract_ref"] = contract_ref;
    if w.evidence is None or w.contract is None {
        result["bound"] = False;
        return result;
    }
    w.evidence.bound = True;
    w.evidence +>:EvidenceBind:+> w.contract;
    result["bound"] = True;
    return result;
}

def admit_runtime_outbox(graph_root: CatalogTable, table_cid: str) -> bool {
    bad: list[str] = verify_column_cascade(graph_root, table_cid);
    if len(bad) > 0 {
        return False;
    }
    tbl = _resolve_table(graph_root, table_cid);
    if tbl is None {
        return False;
    }
    tbl.admitted = True;
    return True;
}

"""Bind batch lifecycle evidence to a released Context Assertion contract.
ContextualWisdomLab/pg-llm-batch#318
"""

node CatalogTable {
    has cid: str;
    has name: str;
    has admitted: bool = False;
}

node Column {
    has cid: str;
    has name: str;
    has atttypmod: int = -1;
}

node BatchEvidence {
    has cid: str;
    has batch_id: str;
    has evidence_id: str = "";
    has bound: bool = False;
}

node ContractAssertion {
    has cid: str;
    has ref: str;
    has version: str;
    has released: bool = False;
}

edge Cascade {}
edge Catalog {}
edge EvidenceBind {}

walker AuthorityWalker {
    has table_cid: str = "";
    has claimed: dict[str, bool] = {};
    has rejected: list[str] = [];

    can probe_table with CatalogTable entry {
        if here.cid != self.table_cid {
            skip;
        }
        print ["authority_probe", here.name];
        cols: list[Column] = [here ->:Catalog:->][?:Column];
        for col in cols {
            visit :0: [col];
        }
        disengage;
    }

    can probe_column with Column entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ["column_probe", here.name, here.atttypmod];
        if here.atttypmod != -1 {
            self.rejected.append(here.name);
        }
        kids: list[Column] = [here ->:Cascade:->][?:Column];
        for kid in kids {
            visit :0: [kid];
        }
        disengage;
    }
}

walker CollectBindWalker {
    has batch_id: str = "";
    has evidence_id: str = "";
    has contract_ref: str = "";
    has claimed: dict[str, bool] = {};
    has evidence: BatchEvidence | None = None;
    has contract: ContractAssertion | None = None;

    can probe_root with CatalogTable entry {
        print ["bind_collect", here.cid];
        evs: list[BatchEvidence] = [here -->][?:BatchEvidence];
        for ev in evs {
            visit [ev];
        }
        cts: list[ContractAssertion] = [here -->][?:ContractAssertion];
        for ct in cts {
            visit [ct];
        }
        disengage;
    }

    can probe_evidence with BatchEvidence entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ["bind_evidence", here.batch_id, here.evidence_id];
        if here.batch_id == self.batch_id {
            if self.evidence_id == "" or here.evidence_id == "" or here.evidence_id == self.evidence_id {
                self.evidence = here;
            }
        }
        disengage;
    }

    can probe_contract with ContractAssertion entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ["bind_contract", here.ref, here.released];
        if here.ref == self.contract_ref and here.released {
            self.contract = here;
        }
        disengage;
    }
}

def _resolve_table(graph_root: CatalogTable, table_cid: str) -> CatalogTable | None {
    if graph_root.cid == table_cid {
        return graph_root;
    }
    return None;
}

def verify_column_cascade(graph_root: CatalogTable, table_cid: str) -> list[str] {
    w = graph_root spawn AuthorityWalker(table_cid=table_cid);
    out: list[str] = w.rejected;
    return sorted(out);
}

def bind_evidence_to_contract(
    graph_root: CatalogTable,
    batch_id: str,
    evidence_id: str,
    contract_ref: str
) -> dict[str, object] {
    w = graph_root spawn CollectBindWalker(
        batch_id=batch_id,
        evidence_id=evidence_id,
        contract_ref=contract_ref
    );
    result: dict[str, object] = {};
    result["batch_id"] = batch_id;
    result["evidence_id"] = evidence_id;
    result["contract_ref"] = contract_ref;
    if w.evidence is None or w.contract is None {
        result["bound"] = False;
        return result;
    }
    w.evidence.bound = True;
    w.evidence +>:EvidenceBind:+> w.contract;
    result["bound"] = True;
    return result;
}

def admit_runtime_outbox(graph_root: CatalogTable, table_cid: str) -> bool {
    bad: list[str] = verify_column_cascade(graph_root, table_cid);
    if len(bad) > 0 {
        return False;
    }
    tbl = _resolve_table(graph_root, table_cid);
    if tbl is None {
        return False;
    }
    tbl.admitted = True;
    return True;
}

def _mk_cascade_table() -> CatalogTable {
    tbl = CatalogTable(cid="t1", name="outbox");
    c1 = Column(cid="c1", name="ok_col", atttypmod=-1);
    c2 = Column(cid="c2", name="bad_col", atttypmod=4);
    c3 = Column(cid="c3", name="deep_bad", atttypmod=8);
    root ++> tbl;
    tbl +>:Catalog:+> c1;
    tbl +>:Catalog:+> c2;
    c2 +>:Cascade:+> c3;
    return tbl;
}

def _mk_bind_graph() -> CatalogTable {
    tbl = CatalogTable(cid="t2", name="bind_tbl");
    ev = BatchEvidence(cid="e1", batch_id="b1", evidence_id="ev1");
    ct = ContractAssertion(cid="a1", ref="ctx/v1", version="1.0.0", released=True);
    root ++> tbl;
    tbl ++> ev;
    tbl ++> ct;
    return tbl;
}

test "verify_column_cascade_rejects_non_default" {
    tbl = _mk_cascade_table();
    bad = verify_column_cascade(tbl, "t1");
    assert bad == ["bad_col", "deep_bad"];
}

test "verify_column_cascade_wrong_table_empty" {
    tbl = _mk_cascade_table();
    bad = verify_column_cascade(tbl, "missing");
    assert bad == [];
}

test "bind_evidence_to_contract_success" {
    tbl = _mk_bind_graph();
    res = bind_evidence_to_contract(tbl, "b1", "ev1", "ctx/v1");
    assert res["bound"] == True;
    assert res["batch_id"] == "b1";
    assert res["evidence_id"] == "ev1";
    assert res["contract_ref"] == "ctx/v1";
    evs: list[BatchEvidence] = [tbl -->][?:BatchEvidence];
    assert evs[0].bound == True;
}

test "bind_evidence_to_contract_unreleased_contract" {
    tbl = _mk_bind_graph();
    cts: list[ContractAssertion] = [tbl -->][?:ContractAssertion];
    cts[0].released = False;
    res = bind_evidence_to_contract(tbl, "b1", "ev1", "ctx/v1");
    assert res["bound"] == False;
}

test "admit_runtime_outbox_rejects_bad_columns" {
    tbl = _mk_cascade_table();
    ok = admit_runtime_outbox(tbl, "t1");
    assert ok == False;
    assert tbl.admitted == False;
}

test "admit_runtime_outbox_admits_clean_table" {
    tbl = CatalogTable(cid="t3", name="clean");
    col = Column(cid="c9", name="only", atttypmod=-1);
    root ++> tbl;
    tbl +>:Catalog:+> col;
    ok = admit_runtime_outbox(tbl, "t3");
    assert ok == True;
    assert tbl.admitted == True;
}
