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
