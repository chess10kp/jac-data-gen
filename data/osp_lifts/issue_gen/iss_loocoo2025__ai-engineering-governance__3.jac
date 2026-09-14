"""loocoo2025/ai-engineering-governance#3 — feedback and approval planning."""

node Feedback {
    has fid: str;
    has disposition: str;
    has summary: str;
    has status: str = "intake";
}
node Artifact {
    has aid: str;
    has phase: str;
}
node Term {
    has short: str;
    has full: str;
    has chinese: str;
}
node ApprovalPackage {
    has boundary: str;
    has units: str;
    has environment: str;
    has measurement: str;
    has rationale: str;
    has verification: str;
    has threshold: float;
    has threshold_unit: str;
}

edge RELATED {}
edge PRECEDES {}
edge ALIAS_OF {}

walker FeedbackWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Feedback entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        self.found.append(here.fid);
        print(here.fid);
        for kid in [here ->:RELATED:->][?:Feedback] {
            visit :0: [kid];
        }
    }
}

walker FeedbackFind {
    has target: str;
    has claimed: dict[str, bool> = {};
    has status: str = "unknown";
    can step with Feedback entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        if here.fid == self.target {
            self.status = here.status;
        }
        print(here.fid);
        for kid in [here ->:RELATED:->][?:Feedback] {
            visit :0: [kid];
        }
    }
}

walker LineageWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with Artifact entry {
        if here.aid in self.claimed { skip; }
        self.claimed[here.aid] = True;
        self.found.append(here.aid);
        print(here.aid);
        for prior in [here ->:PRECEDES:->][?:Artifact] {
            visit :0: [prior];
        }
    }
}

walker AliasWalk {
    has claimed: dict[str, bool] = {};
    has canonical: str = "";
    can step with Term entry {
        if here.short in self.claimed { skip; }
        self.claimed[here.short] = True;
        if here.full != "" {
            self.canonical = here.full;
        }
        print(here.short);
        for term in [here ->:ALIAS_OF:->][?:Term] {
            visit :0: [term];
        }
    }
}

def new_feedback(fid: str, disposition: str, summary: str) -> Feedback {
    return Feedback(fid=fid, disposition=disposition, summary=summary);
}

def connect_feedback(source: Feedback, target: Feedback) -> bool {
    source +>:RELATED:+> target;
    return True;
}

def collect_feedback(graph_root: Feedback) -> list[str] {
    w = graph_root spawn FeedbackWalk(claimed={});
    return sorted(w.found);
}

def feedback_status(graph_root: Feedback, feedback_id: str) -> str {
    w = graph_root spawn FeedbackFind(target=feedback_id, claimed={});
    return w.status;
}

def new_approval(
    boundary: str,
    units: str,
    environment: str,
    measurement: str,
    rationale: str,
    verification: str,
    threshold: float,
    threshold_unit: str
) -> ApprovalPackage {
    return ApprovalPackage(
        boundary=boundary,
        units=units,
        environment=environment,
        measurement=measurement,
        rationale=rationale,
        verification=verification,
        threshold=threshold,
        threshold_unit=threshold_unit
    );
}

def approval_ready(pkg: ApprovalPackage) -> bool {
    return pkg.boundary != ""
        and pkg.units != ""
        and pkg.environment != ""
        and pkg.measurement != ""
        and pkg.rationale != ""
        and pkg.verification != ""
        and pkg.threshold >= 0.0
        and pkg.threshold_unit != "";
}

def decide(pkg: ApprovalPackage, decision: str) -> str {
    if decision == "approve" { return "approved"; }
    if decision == "request_changes" { return "changes_requested"; }
    if decision == "reject" { return "rejected"; }
    return "deferred";
}

def collect_lineage(graph_root: Artifact) -> list[str] {
    w = graph_root spawn LineageWalk(claimed={});
    return sorted(w.found);
}

def resolve_term(graph_root: Term) -> str {
    w = graph_root spawn AliasWalk(claimed={});
    if w.canonical == "" {
        return graph_root.short;
    }
    return w.canonical;
}
