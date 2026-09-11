"""Herd-OS/herd#1050 — review workflow status transition reachability."""

glob CANONICAL: list[str] = [
    "approved", "changes_requested", "failed", "timed_out", "unparseable"
];

node ReviewStatus {
    has name: str;
}

edge Allows {}

obj ReviewWorkflow {
    has statuses: dict[str, ReviewStatus] = {};
}

walker StatusReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has anchor: str = "";

    can step with ReviewStatus entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.anchor { self.reached.append(here.name); }
        visit [->:Allows:->][?:ReviewStatus];
    }
}

def load_review_workflow(
    statuses: list[str],
    transition_edges: list[tuple[str, str]],
) -> ReviewWorkflow {
    wf = ReviewWorkflow();
    for st in statuses {
        nd = ReviewStatus(name=st);
        root ++> nd;
        wf.statuses[st] = nd;
    }
    for (src, dst) in transition_edges {
        s = wf.statuses.get(src, None);
        d = wf.statuses.get(dst, None);
        if s is not None and d is not None { s +>:Allows:+> d; }
    }
    return wf;
}

def reachable_statuses(store: ReviewWorkflow, from_status: str) -> list[str] {
    nd = store.statuses.get(from_status, None);
    if nd is None { return []; }
    w = nd spawn StatusReach(claimed={}, anchor=from_status);
    return sorted(w.reached);
}

def can_transition(store: ReviewWorkflow, from_status: str, to_status: str) -> bool {
    s = store.statuses.get(from_status, None);
    if s is None { return False; }
    if to_status not in store.statuses { return False; }
    for d in [s ->:Allows:->][?:ReviewStatus] {
        if d.name == to_status { return True; }
    }
    return False;
}

def normalize_status(store: ReviewWorkflow, raw: str) -> str | None {
    mapped = raw;
    if raw == "timeout" { mapped = "timed_out"; }
    if raw == "timedout" { mapped = "timed_out"; }
    if mapped in store.statuses { return mapped; }
    for c in CANONICAL {
        if c == mapped { return mapped if mapped in store.statuses else None; }
    }
    return None;
}

test "review status reach" {
    wf = load_review_workflow(
        ["pending", "running", "approved", "changes_requested", "failed", "timed_out", "unparseable"],
        [
            ("pending", "running"),
            ("running", "approved"),
            ("running", "changes_requested"),
            ("running", "failed"),
            ("running", "timed_out"),
            ("running", "unparseable"),
        ],
    );
    assert reachable_statuses(wf, "running") == [
        "approved", "changes_requested", "failed", "timed_out", "unparseable"
    ];
    assert normalize_status(wf, "timeout") == "timed_out";
}

test "status diamond revisit" {
    wf = load_review_workflow(
        ["start", "a", "b", "done"],
        [("start", "a"), ("start", "b"), ("a", "done"), ("b", "done")],
    );
    assert reachable_statuses(wf, "start") == ["a", "b", "done"];
}
