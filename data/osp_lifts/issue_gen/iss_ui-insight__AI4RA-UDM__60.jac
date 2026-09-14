"""ui-insight/AI4RA-UDM#60"""

node Protocol { has protocol_id: str; has regime: str; has lifecycle: str; }
node ProtocolCoverage { has coverage_id: str; has target_id: str; has target_kind: str; }
node ProtocolPersonnel { has person_id: str; has training_status: str; has scope_id: str; }
node ProtocolReviewStep { has step_id: str; has parent_kind: str; has status: str; }
node ProtocolAmendment { has event_id: str; has lifecycle: str; }
node ProtocolContinuingReview { has event_id: str; has lifecycle: str; }
node ProtocolAdverseEvent { has event_id: str; has lifecycle: str; }
node ProtocolDeviation { has event_id: str; has lifecycle: str; }
node AnimalUseSpecies { has detail_id: str; has name: str; has count: int; }
node AnimalUseProcedure { has detail_id: str; has name: str; has pain_category: str; }
node AnimalUseHazard { has detail_id: str; has agent: str; has containment_level: str; }
node AnimalUseAlternativesSearch { has detail_id: str; has query: str; has searched_on: str; }
node AnimalUseClosureReport { has detail_id: str; has outcome: str; has closed_on: str; }
node HumanSubjectsPopulation { has detail_id: str; has description: str; has risk_level: str; }
node HumanSubjectsIntervention { has detail_id: str; has name: str; has intervention_type: str; }
node HumanSubjectsConsent { has detail_id: str; has version: str; has status: str; }
node BiologicalAgent { has detail_id: str; has name: str; has containment_level: str; }
node BiosafetyProcedure { has detail_id: str; has name: str; has containment_level: str; }

edge HasPart {}
edge ParentOf {}
edge Covers {}
edge Assigns {}

obj ComplianceStore {
    has protocols: list[Protocol] = [];
    has amendments: list[ProtocolAmendment] = [];
    has reviews: list[ProtocolReviewStep] = [];
}

def new_store() -> ComplianceStore { return ComplianceStore(); }

def protocol_for(store: ComplianceStore, protocol_id: str) -> Protocol | None {
    for p in store.protocols { if p.protocol_id == protocol_id { return p; } }
    return None;
}

def add_protocol(store: ComplianceStore, protocol_id: str, regime: str, lifecycle: str = "draft") -> Protocol {
    for p in store.protocols { if p.protocol_id == protocol_id { return p; } }
    p = Protocol(protocol_id=protocol_id, regime=regime, lifecycle=lifecycle);
    store.protocols.append(p);
    return p;
}

def add_coverage(store: ComplianceStore, protocol_id: str, coverage_id: str, target_id: str, target_kind: str) -> bool {
    p = protocol_for(store, protocol_id);
    if p is None or (target_kind != "award" and target_kind != "subaward") { return False; }
    c = ProtocolCoverage(coverage_id=coverage_id, target_id=target_id, target_kind=target_kind);
    p +>:Covers:+> c;
    return True;
}

def add_personnel(store: ComplianceStore, protocol_id: str, person_id: str, training_status: str, scope_id: str = "") -> bool {
    p = protocol_for(store, protocol_id);
    if p is None { return False; }
    x = ProtocolPersonnel(person_id=person_id, training_status=training_status, scope_id=scope_id);
    p +>:Assigns:+> x;
    return True;
}

def add_event(store: ComplianceStore, protocol_id: str, event_id: str, kind: str, lifecycle: str) -> bool {
    p = protocol_for(store, protocol_id);
    if p is None { return False; }
    if kind == "amendment" {
        x = ProtocolAmendment(event_id=event_id, lifecycle=lifecycle);
        store.amendments.append(x); p +>:HasPart:+> x; return True;
    } elif kind == "continuing_review" {
        x = ProtocolContinuingReview(event_id=event_id, lifecycle=lifecycle);
        p +>:HasPart:+> x; return True;
    } elif kind == "adverse_event" {
        x = ProtocolAdverseEvent(event_id=event_id, lifecycle=lifecycle);
        p +>:HasPart:+> x; return True;
    } elif kind == "deviation" {
        x = ProtocolDeviation(event_id=event_id, lifecycle=lifecycle);
        p +>:HasPart:+> x; return True;
    }
    return False;
}

def add_review_step(store: ComplianceStore, protocol_id: str, step_id: str, parent_id: str, parent_kind: str, status: str) -> bool {
    p = protocol_for(store, protocol_id);
    if p is None { return False; }
    parent_found: bool = parent_kind == "protocol";
    if parent_kind == "amendment" {
        for a in store.amendments { if a.event_id == parent_id { parent_found = True; } }
    }
    if not parent_found { return False; }
    s = ProtocolReviewStep(step_id=step_id, parent_kind=parent_kind, status=status);
    store.reviews.append(s); p +>:ParentOf:+> s;
    if parent_kind == "amendment" {
        for a in store.amendments { if a.event_id == parent_id { a +>:ParentOf:+> s; } }
    }
    return True;
}

def add_detail(store: ComplianceStore, protocol_id: str, kind: str, detail_id: str, label: str, value: str, count: int = 0) -> bool {
    p = protocol_for(store, protocol_id);
    if p is None or count < 0 { return False; }
    if kind == "animal_species" and p.regime == "IACUC" {
        x = AnimalUseSpecies(detail_id=detail_id, name=label, count=count); p +>:HasPart:+> x; return True;
    } elif kind == "animal_procedure" and p.regime == "IACUC" {
        x = AnimalUseProcedure(detail_id=detail_id, name=label, pain_category=value); p +>:HasPart:+> x; return True;
    } elif kind == "animal_hazard" and p.regime == "IACUC" {
        x = AnimalUseHazard(detail_id=detail_id, agent=label, containment_level=value); p +>:HasPart:+> x; return True;
    } elif kind == "alternatives_search" and p.regime == "IACUC" {
        x = AnimalUseAlternativesSearch(detail_id=detail_id, query=label, searched_on=value); p +>:HasPart:+> x; return True;
    } elif kind == "closure_report" and p.regime == "IACUC" {
        x = AnimalUseClosureReport(detail_id=detail_id, outcome=label, closed_on=value); p +>:HasPart:+> x; return True;
    } elif kind == "population" and p.regime == "IRB" {
        x = HumanSubjectsPopulation(detail_id=detail_id, description=label, risk_level=value); p +>:HasPart:+> x; return True;
    } elif kind == "intervention" and p.regime == "IRB" {
        x = HumanSubjectsIntervention(detail_id=detail_id, name=label, intervention_type=value); p +>:HasPart:+> x; return True;
    } elif kind == "consent" and p.regime == "IRB" {
        x = HumanSubjectsConsent(detail_id=detail_id, version=label, status=value); p +>:HasPart:+> x; return True;
    } elif kind == "biological_agent" and p.regime == "IBC" {
        x = BiologicalAgent(detail_id=detail_id, name=label, containment_level=value); p +>:HasPart:+> x; return True;
    } elif kind == "biosafety_procedure" and p.regime == "IBC" {
        x = BiosafetyProcedure(detail_id=detail_id, name=label, containment_level=value); p +>:HasPart:+> x; return True;
    }
    return False;
}

walker ReviewClosure {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can collect_protocol with Protocol entry {
        key: str = "protocol:" + here.protocol_id;
        if key in self.claimed { skip; }
        self.claimed[key] = True; self.found.append(here.protocol_id); print(here.protocol_id);
        for a in [here ->:HasPart:->][?:ProtocolAmendment] { visit :0: [a]; }
        for s in [here ->:ParentOf:->][?:ProtocolReviewStep] { visit :0: [s]; }
    }

    can collect_amendment with ProtocolAmendment entry {
        key: str = "amendment:" + here.event_id;
        if key in self.claimed { skip; }
        self.claimed[key] = True; self.found.append(here.event_id); print(here.event_id);
        for s in [here ->:ParentOf:->][?:ProtocolReviewStep] { visit :0: [s]; }
    }

    can collect_step with ProtocolReviewStep entry {
        key: str = "step:" + here.step_id;
        if key in self.claimed { skip; }
        self.claimed[key] = True; self.found.append(here.step_id); print(here.step_id);
    }
}

def review_ids(store: ComplianceStore, protocol_id: str) -> list[str] {
    p = protocol_for(store, protocol_id);
    if p is None { return []; }
    w = p spawn ReviewClosure(claimed={});
    return sorted(w.found);
}
