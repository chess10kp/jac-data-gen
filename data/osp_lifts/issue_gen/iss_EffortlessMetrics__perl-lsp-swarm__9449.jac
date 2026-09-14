# PROGRAM: iss_EffortlessMetrics__perl-lsp-swarm__9449.jac
"""EffortlessMetrics/perl-lsp-swarm#9449 workflow retirement authority cleanup."""

node Workflow {
    has wid: str;
    has label: str;
    has classification: str;
    has executable: bool = True;
    has retired: bool = False;
    has reason: str = "";
}
node Consumer {
    has cid: str;
    has role: str;
    has active: bool = True;
    has authoritative: bool = False;
}
node Evidence {
    has location: str;
    has kind: str;
}
edge Calls {}
edge References {}
edge HasEvidence {}

obj Catalog {
    has workflows: list[Workflow] = [];
    has consumers: list[Consumer] = [];
    has evidence: list[Evidence] = [];
}

walker Reach {
    has claimed: dict[str, bool] = {};
    has callers: list[str] = [];
    has locations: list[str] = [];

    can step_workflow with Workflow entry {
        key = "w:" + here.wid;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        for consumer in [here ->:Calls:->][?:Consumer] {
            visit :0: [consumer];
        }
        for item in [here ->:HasEvidence:->][?:Evidence] {
            visit :0: [item];
        }
    }
    can step_consumer with Consumer entry {
        key = "c:" + here.cid;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        self.callers.append(here.cid);
        print(here.cid);
        for target in [here ->:References:->][?:Workflow] {
            visit :0: [target];
        }
    }
    can step_evidence with Evidence entry {
        key = "e:" + here.location;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        self.locations.append(here.location);
        print(here.location);
    }
}

def new_catalog -> Catalog {
    return Catalog;
}

def find_workflow(catalog: Catalog, wid: str) -> Workflow | None {
    for workflow in catalog.workflows {
        if workflow.wid == wid { return workflow; }
    }
    return None;
}

def find_consumer(catalog: Catalog, cid: str) -> Consumer | None {
    for consumer in catalog.consumers {
        if consumer.cid == cid { return consumer; }
    }
    return None;
}

def add_workflow(catalog: Catalog, wid: str, label: str, classification: str) -> Workflow {
    workflow = Workflow(wid=wid, label=label, classification=classification);
    catalog.workflows.append(workflow);
    return workflow;
}

def add_consumer(
    catalog: Catalog, cid: str, role: str, active: bool, authoritative: bool
) -> Consumer {
    consumer = Consumer(cid=cid, role=role, active=active, authoritative=authoritative);
    catalog.consumers.append(consumer);
    return consumer;
}

def link_caller(catalog: Catalog, wid: str, cid: str) -> bool {
    workflow = find_workflow(catalog, wid);
    consumer = find_consumer(catalog, cid);
    if workflow is None or consumer is None { return False; }
    workflow +>:Calls:+> consumer;
    return True;
}

def link_reference(catalog: Catalog, cid: str, wid: str) -> bool {
    consumer = find_consumer(catalog, cid);
    workflow = find_workflow(catalog, wid);
    if consumer is None or workflow is None { return False; }
    consumer +>:References:+> workflow;
    return True;
}

def record_history(catalog: Catalog, wid: str, location: str, kind: str) -> bool {
    workflow = find_workflow(catalog, wid);
    if workflow is None { return False; }
    item = Evidence(location=location, kind=kind);
    catalog.evidence.append(item);
    workflow +>:HasEvidence:+> item;
    return True;
}

def reachable_callers(workflow: Workflow) -> list[str] {
    w = workflow spawn Reach(claimed={});
    return sorted(w.callers);
}

def has_active_authority(catalog: Catalog, workflow: Workflow) -> bool {
    w = workflow spawn Reach(claimed={});
    for cid in w.callers {
        consumer = find_consumer(catalog, cid);
        if consumer is not None and consumer.active and consumer.authoritative {
            return True;
        }
    }
    return False;
}

def workflow_status(catalog: Catalog, wid: str) -> str {
    workflow = find_workflow(catalog, wid);
    if workflow is None { return "unknown"; }
    if workflow.retired { return "retired"; }
    if workflow.executable { return "executable"; }
    return "disabled";
}

def retirement_candidates(catalog: Catalog) -> list[str] {
    candidates: list[str] = [];
    for workflow in catalog.workflows {
        if workflow.executable
            and workflow.classification in ["orphan", "expired", "obsolete", "duplicate_context"]
            and not has_active_authority(catalog, workflow) {
            candidates.append(workflow.wid);
        }
    }
    return sorted(candidates);
}

def retire_workflow(catalog: Catalog, wid: str, reason: str) -> bool {
    workflow = find_workflow(catalog, wid);
    if workflow is None or not workflow.executable { return False; }
    if has_active_authority(catalog, workflow) { return False; }
    w = workflow spawn Reach(claimed={});
    if len(w.locations) == 0 { return False; }
    workflow.executable = False;
    workflow.retired = True;
    workflow.reason = reason;
    return True;
}
