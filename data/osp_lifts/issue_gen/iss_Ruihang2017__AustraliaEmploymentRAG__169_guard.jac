"""Idiomatic OSP lift for Ruihang2017/AustraliaEmploymentRAG#169."""

edge Contains {}
edge Replaces {}
edge Replacement {}
edge Impacts {}
edge Related {}
edge HoldsRecord {}

node ResearchRecord {
    has record_id: str;
    has customer_id: str;
    has review_state: str = "ACTIVE";
    has review_reason: str = "";
}

node AnswerSnapshot {
    has snapshot_id: str;
    has customer_id: str;
    has answer_text: str;
    has correction_state: str = "NONE";
}

node CorrectionCase {
    has case_id: str;
    has reason: str;
    has status: str = "CONFIRMED";
}

node CorrectionRegistry {}

walker ImpactWalker {
    has claimed: dict[str, bool] = {};
    has affected: list[str] = [];
    has customer_ids: list[str] = [];

    can inspect with CorrectionCase entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for record in [here ->:Impacts:->][?:ResearchRecord] {
            visit :0: [record];
        }
        print("impact analysis started");
    }

    can inspect_record with ResearchRecord entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        here.review_state = "REVIEW_REQUIRED";
        self.affected.append(here.record_id);
        var already: bool = False;
        for customer_id in self.customer_ids {
            if customer_id == here.customer_id {
                already = True;
            }
        }
        if not already {
            self.customer_ids.append(here.customer_id);
        }
        for related in [here ->:Related:->][?:ResearchRecord] {
            visit :0: [related];
        }
        print("record marked for review");
    }
}

def new_case -> CorrectionCase {
    return CorrectionCase(case_id="case", reason="pending");
}

def new_registry -> CorrectionRegistry {
    return CorrectionRegistry();
}

def make_record(record_id: str, customer_id: str) -> ResearchRecord {
    return ResearchRecord(record_id=record_id, customer_id=customer_id);
}

def make_snapshot(snapshot_id: str, customer_id: str, answer_text: str) -> AnswerSnapshot {
    return AnswerSnapshot(
        snapshot_id=snapshot_id,
        customer_id=customer_id,
        answer_text=answer_text
    );
}

def attach_snapshot(record: ResearchRecord, snapshot: AnswerSnapshot) -> None {
    record +>:Contains:+> snapshot;
    return None;
}

def confirm_correction(
    original: AnswerSnapshot,
    replacement: AnswerSnapshot,
    reason: str
) -> CorrectionCase {
    case = CorrectionCase(case_id=original.snapshot_id, reason=reason);
    replacement +>:Replaces:+> original;
    case +>:Replacement:+> replacement;
    original.correction_state = "CORRECTED";
    replacement.correction_state = "NONE";
    return case;
}

def attach_impact(case: CorrectionCase, record: ResearchRecord) -> None {
    case +>:Impacts:+> record;
    return None;
}

def relate_records(first: ResearchRecord, second: ResearchRecord) -> None {
    first +>:Related:+> second;
    return None;
}

def register_record(
    registry: CorrectionRegistry,
    record: ResearchRecord
) -> CorrectionRegistry {
    registry +>:HoldsRecord:+> record;
    return registry;
}

def find_record(
    registry: CorrectionRegistry,
    record_id: str
) -> ResearchRecord | None {
    for record in [registry ->:HoldsRecord:->][?:ResearchRecord] {
        if record.record_id == record_id {
            return record;
        }
    }
    return None;
}

def analyze_impact(case: CorrectionCase) -> list[str] {
    w = case spawn ImpactWalker(claimed={});
    return sorted(w.affected);
}

def affected_customers(case: CorrectionCase) -> list[str] {
    w = case spawn ImpactWalker(claimed={});
    return sorted(w.customer_ids);
}

test "preserves original and links replacement" {
    original = make_snapshot("old", "cust-1", "old answer");
    replacement = make_snapshot("new", "cust-1", "correct answer");
    case = confirm_correction(original, replacement, "wrong date");

    assert (original.answer_text == "old answer");
    assert (original.correction_state == "CORRECTED");
    assert (replacement.correction_state == "NONE");
    assert (case.reason == "wrong date");

    var linked: bool = False;
    for snapshot in [case ->:Replacement:->][?:AnswerSnapshot] {
        if snapshot.snapshot_id == "new" {
            linked = True;
        }
    }
    assert (linked);
}

test "diamond impact traversal skips revisit" {
    case = new_case;
    first = make_record("r1", "cust-1");
    second = make_record("r2", "cust-2");
    shared = make_record("r3", "cust-1");

    attach_impact(case, first);
    attach_impact(case, second);
    relate_records(first, shared);
    relate_records(second, shared);

    impacted = analyze_impact(case);
    assert (impacted == ["r1", "r2", "r3"]);
    assert (shared.review_state == "REVIEW_REQUIRED");
    assert (affected_customers(case) == ["cust-1", "cust-2"]);
}

test "unknown record id is tolerated" {
    registry = new_registry;
    record = make_record("known", "cust-1");
    register_record(registry, record);

    found = find_record(registry, "known");
    missing = find_record(registry, "missing");

    assert (found is not None);
    assert (found.record_id == "known");
    assert (missing is None);
}

test "empty impact has no affected records" {
    case = new_case;
    assert (analyze_impact(case) == []);
    assert (affected_customers(case) == []);
}
