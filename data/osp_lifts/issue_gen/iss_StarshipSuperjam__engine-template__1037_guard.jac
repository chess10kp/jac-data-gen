# StarshipSuperjam/engine-template#1037
node IntakeRoot {}
node Capability {
    has cid: str;
    has label: str;
    has decision_applicable: bool = False;
    has disposition: str = "normal-sdd";
}
node Decision {
    has did: str;
    has question: str;
    has outcomes: list[str] = [];
}
node Requirement {
    has rid: str;
    has kind: str;
    has detail: str;
}
edge Catalog {}
edge HasDecision {}
edge Requires {}
edge DependsOn {}

obj IntakeState {
    has graph_root: IntakeRoot | None = None;
    has capabilities: dict[str, Capability] = {};
    has decisions: dict[str, Decision] = {};
    has requirements: dict[str, Requirement] = {};
}

walker DependencyWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Decision entry {
        if here.did in self.claimed { skip; }
        self.claimed[here.did] = True;
        self.found.append(here.did);
        print(here.did);
        for dep in [here ->:DependsOn:->][?:Decision] {
            visit :0: [dep];
        }
    }
}

walker RequirementsWalker {
    has claimed: dict[str, bool] = {};
    has rows: list[str] = [];

    can scan_cap with Capability entry {
        if ("c:" + here.cid) in self.claimed { skip; }
        self.claimed["c:" + here.cid] = True;
        print(here.cid);
        for dec in [here ->:HasDecision:->][?:Decision] {
            visit :0: [dec];
        }
    }

    can scan_dec with Decision entry {
        if ("d:" + here.did) in self.claimed { skip; }
        self.claimed["d:" + here.did] = True;
        self.rows.append("decision:" + here.did + ":" + here.question);
        print(here.did);
        for outcome in here.outcomes {
            self.rows.append("outcome:" + here.did + ":" + outcome);
        }
        for req in [here ->:Requires:->][?:Requirement] {
            visit :0: [req];
        }
        for dep in [here ->:DependsOn:->][?:Decision] {
            self.rows.append("depends:" + here.did + ":" + dep.did);
            visit :0: [dep];
        }
    }

    can scan_req with Requirement entry {
        if ("r:" + here.rid) in self.claimed { skip; }
        self.claimed["r:" + here.rid] = True;
        self.rows.append(here.kind + ":" + here.rid + ":" + here.detail);
        print(here.rid);
    }
}

def new_intake() -> IntakeState {
    state = IntakeState();
    state.graph_root = IntakeRoot();
    return state;
}

def add_capability(state: IntakeState, cid: str, label: str) -> Capability | None {
    if state.graph_root == None { return None; }
    cap = Capability(cid=cid, label=label);
    state.graph_root +>:Catalog:+> cap;
    state.capabilities[cid] = cap;
    return cap;
}

def screen_decision_lens(
    state: IntakeState,
    cid: str,
    repeatable: bool,
    rule_governed: bool,
    inputs_identifiable: bool,
    outcomes_identifiable: bool
) -> str {
    if cid not in state.capabilities { return "unknown"; }
    cap = state.capabilities[cid];
    cap.decision_applicable =
        repeatable and rule_governed and inputs_identifiable and outcomes_identifiable;
    if cap.decision_applicable {
        cap.disposition = "decision-requirements";
    } else {
        cap.disposition = "normal-sdd";
    }
    return cap.disposition;
}

def add_decision(
    state: IntakeState, cid: str, did: str, question: str
) -> Decision | None {
    if cid not in state.capabilities { return None; }
    cap = state.capabilities[cid];
    dec = Decision(did=did, question=question);
    cap +>:HasDecision:+> dec;
    state.decisions[did] = dec;
    return dec;
}

def add_outcome(state: IntakeState, did: str, outcome: str) -> bool {
    if did not in state.decisions { return False; }
    state.decisions[did].outcomes.append(outcome);
    return True;
}

def add_requirement(
    state: IntakeState, did: str, rid: str, kind: str, detail: str
) -> Requirement | None {
    if did not in state.decisions { return None; }
    req = Requirement(rid=rid, kind=kind, detail=detail);
    state.decisions[did] +>:Requires:+> req;
    state.requirements[rid] = req;
    return req;
}

def link_dependent_decision(state: IntakeState, did: str, dependency_id: str) -> bool {
    if did not in state.decisions or dependency_id not in state.decisions {
        return False;
    }
    state.decisions[did] +>:DependsOn:+> state.decisions[dependency_id];
    return True;
}

def decision_closure(state: IntakeState, did: str) -> list[str] {
    if did not in state.decisions { return []; }
    w = state.decisions[did] spawn DependencyWalker(claimed={}, found=[]);
    return sorted(w.found);
}

def decision_requirements(state: IntakeState, cid: str) -> list[str] {
    if cid not in state.capabilities { return []; }
    cap = state.capabilities[cid];
    if not cap.decision_applicable { return []; }
    w = cap spawn RequirementsWalker(claimed={}, rows=[]);
    return sorted(w.rows);
}

test "plain_sdd_keeps_normal_path" {
    state = new_intake();
    add_capability(state, "search", "Search catalog");
    assert (screen_decision_lens(state, "search", False, False, False, False) == "normal-sdd");
    assert (decision_requirements(state, "search") == []);
}

test "decision_screen_builds_canonical_requirements" {
    state = new_intake();
    add_capability(state, "refund", "Refund order");
    assert (screen_decision_lens(state, "refund", True, True, True, True) == "decision-requirements");
    add_decision(state, "refund", "eligibility", "Approve or deny refund");
    add_outcome(state, "eligibility", "approve");
    add_outcome(state, "eligibility", "deny");
    add_requirement(state, "eligibility", "amount", "input", "Order total from ledger");
    add_requirement(state, "eligibility", "policy", "authority", "Refund policy");
    rows = decision_requirements(state, "refund");
    assert ("decision:eligibility:Approve or deny refund" in rows);
    assert ("outcome:eligibility:approve" in rows);
    assert ("input:amount:Order total from ledger" in rows);
    assert ("authority:policy:Refund policy" in rows);
}

test "diamond_revisit_and_cycle_are_once_only" {
    state = new_intake();
    add_capability(state, "risk", "Risk review");
    screen_decision_lens(state, "risk", True, True, True, True);
    add_decision(state, "risk", "a", "A");
    add_decision(state, "risk", "b", "B");
    add_decision(state, "risk", "c", "C");
    add_decision(state, "risk", "d", "D");
    link_dependent_decision(state, "a", "b");
    link_dependent_decision(state, "a", "c");
    link_dependent_decision(state, "b", "d");
    link_dependent_decision(state, "c", "d");
    link_dependent_decision(state, "d", "a");
    assert (decision_closure(state, "a") == ["a", "b", "c", "d"]);
}

test "unknown_ids_are_tolerated" {
    state = new_intake();
    assert (screen_decision_lens(state, "missing", True, True, True, True) == "unknown");
    assert (add_decision(state, "missing", "d", "Missing") == None);
    assert (add_requirement(state, "missing", "r", "input", "none") == None);
    assert (link_dependent_decision(state, "missing", "other") == False);
    assert (decision_closure(state, "missing") == []);
    assert (decision_requirements(state, "missing") == []);
}
