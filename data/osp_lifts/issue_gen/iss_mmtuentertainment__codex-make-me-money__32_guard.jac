"""Guard: mmtuentertainment/codex-make-me-money#32."""

node RepairRecord { has rid: str; has failed: bool = False; }
edge Predecessor {}

obj RepairLedger { has records: dict[str, RepairRecord] = {}; }

walker PredecessorWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with RepairRecord entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        self.found.append(here.rid);
        for par in [here <-:Predecessor:<-][?:RepairRecord] {
            if not (par.rid in self.claimed) { visit [par]; }
        }
    }
}

def load_ledger(
    records: list[str],
    lineage: list[tuple[str, str]],
    failed: list[str],
) -> RepairLedger {
    ledger = RepairLedger();
    fail_set: dict[str, bool] = {};
    for f in failed { fail_set[f] = True; }
    for rid in records {
        nd = RepairRecord(rid=rid, failed=(rid in fail_set));
        root ++> nd;
        ledger.records[rid] = nd;
    }
    for (child, parent) in lineage {
        c = ledger.records.get(child, None);
        p = ledger.records.get(parent, None);
        if c is not None and p is not None { p +>:Predecessor:+> c; }
    }
    return ledger;
}

def lineage_trail(ledger: RepairLedger, record_id: str) -> list[str] {
    nd = ledger.records.get(record_id, None);
    if nd is None { return []; }
    w = nd spawn PredecessorWalk(claimed={}, found=[]);
    out: dict[str, bool] = {record_id: True};
    for r in w.found { out[r] = True; }
    keys: list[str] = [];
    for k in out.keys() { keys.append(k); }
    return sorted(keys);
}

def failure_evidence(ledger: RepairLedger, record_id: str) -> list[str] {
    trail = lineage_trail(ledger, record_id);
    hits: list[str] = [];
    for rid in trail {
        nd = ledger.records.get(rid, None);
        if nd is not None and nd.failed { hits.append(rid); }
    }
    return sorted(hits);
}

test "lineage trail preserves predecessors" {
    l = load_ledger(
        ["r1", "r2", "r3", "r4"],
        [("r2", "r1"), ("r3", "r2"), ("r4", "r3")],
        ["r2"],
    );
    assert lineage_trail(l, "r4") == ["r1", "r2", "r3", "r4"];
    assert failure_evidence(l, "r4") == ["r2"];
}

test "unknown record empty" {
    l = load_ledger(["solo"], [], []);
    assert lineage_trail(l, "ghost") == [];
}
