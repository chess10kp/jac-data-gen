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

test "diamond revisit is claimed once" {
    a = new_feedback("a", "CORE_NEW", "root");
    b = new_feedback("b", "CORE_NEW", "branch");
    c = new_feedback("c", "CORE_CLARIFICATION", "branch");
    d = new_feedback("d", "EXISTING_VERIFY", "shared");
    connect_feedback(a, b);
    connect_feedback(b, d);
    connect_feedback(a, c);
    connect_feedback(c, d);
    assert (collect_feedback(a) == ["a", "b", "c", "d"]);
}

test "feedback cycle does not truncate closure" {
    a = new_feedback("a", "CORE_NEW", "one");
    b = new_feedback("b", "CORE_NEW", "two");
    c = new_feedback("c", "CORE_NEW", "three");
    connect_feedback(a, b);
    connect_feedback(b, c);
    connect_feedback(c, a);
    assert (collect_feedback(a) == ["a", "b", "c"]);
}

test "unknown feedback id is tolerated" {
    a = new_feedback("known", "CORE_CLARIFICATION", "recorded");
    assert (feedback_status(a, "missing") == "unknown");
}

test "threshold package requires complete evidence" {
    p = new_approval("C04", "", "staging", "latency", "rollback", "sample", 10.0, "ms");
    assert (approval_ready(p) == False);
    p.units = "milliseconds";
    assert (approval_ready(p) == True);
    assert (decide(p, "approve") == "approved");
    assert (decide(p, "request_changes") == "changes_requested");
    assert (decide(p, "defer") == "deferred");
    assert (decide(p, "reject") == "rejected");
}

test "lineage and alias cycles remain finite" {
    a = Artifact(aid="plan", phase="plan");
    b = Artifact(aid="build", phase="build");
    a +>:PRECEDES:+> b;
    b +>:PRECEDES:+> a;
    assert (collect_lineage(a) == ["build", "plan"]);

    alias = Term(short="PRD", full="", chinese="产品需求文档");
    canonical = Term(
        short="PRD",
        full="Product Requirements Document",
        chinese="产品需求文档"
    );
    alias +>:ALIAS_OF:+> canonical;
    canonical +>:ALIAS_OF:+> alias;
    assert (resolve_term(alias) == "Product Requirements Document");
}
