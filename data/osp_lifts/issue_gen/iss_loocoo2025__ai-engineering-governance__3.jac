# iss_loocoo2025__ai-engineering-governance__3.jac
# loocoo2025/ai-engineering-governance#3 — consolidated v0.1.4 field-feedback planning graph.

node Feedback {
    has fid: str;
    has disposition: str;
    has boundary: str;
}

edge Related {}

node FeedbackGraph {
    has items: dict[str, Feedback] = {};
}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can traverse with Feedback entry {
        if here.fid in self.claimed {
            skip;
        }
        self.claimed[here.fid] = True;
        self.found.append(here.fid);
        print(["feedback_visit", here.fid]);
        nbrs: list[Feedback] = [];
        for nb in [here ->:Related:->][?:Feedback] {
            nbrs.append(nb);
        }
        if nbrs {
            visit :0: nbrs;
        } else {
            disengage;
        }
    }
}

def make_registry() -> FeedbackGraph {
    g = FeedbackGraph();
    f001 = Feedback(fid="V014-FB-001", disposition="CORE_NEW", boundary="approval_summary");
    f002 = Feedback(fid="V014-FB-002", disposition="CORE_CLARIFICATION", boundary="glossary_reuse");
    f003 = Feedback(fid="V014-FB-003", disposition="CORE_NEW", boundary="threshold_package");
    f004 = Feedback(fid="V014-FB-004", disposition="CORE_NEW", boundary="route_preview");
    f005 = Feedback(fid="V014-FB-005", disposition="CORE_CLARIFICATION", boundary="decision_states");
    f006 = Feedback(fid="V014-FB-006", disposition="CORE_CLARIFICATION", boundary="editorial_change");
    f007 = Feedback(fid="V014-FB-007", disposition="CORE_NEW", boundary="feedback_lifecycle");
    f008 = Feedback(fid="V014-FB-008", disposition="CORE_CLARIFICATION", boundary="release_freeze");
    g.items["V014-FB-001"] = f001;
    g.items["V014-FB-002"] = f002;
    g.items["V014-FB-003"] = f003;
    g.items["V014-FB-004"] = f004;
    g.items["V014-FB-005"] = f005;
    g.items["V014-FB-006"] = f006;
    g.items["V014-FB-007"] = f007;
    g.items["V014-FB-008"] = f008;
    f001 +>:Related:+> f007;
    f007 +>:Related:+> f001;
    f004 +>:Related:+> f003;
    f004 +>:Related:+> f005;
    f003 +>:Related:+> f006;
    f005 +>:Related:+> f006;
    f002 +>:Related:+> f008;
    return g;
}

def is_known_feedback(g: FeedbackGraph, fid: str) -> bool {
    return fid in g.items;
}

def feedback_closure(g: FeedbackGraph, start_fid: str) -> list[str] {
    if start_fid not in g.items {
        return [];
    }
    start_node = g.items[start_fid];
    root ++> start_node;
    wk = start_node spawn ClosureWalker();
    acc: list[str] = [];
    for v in wk.found {
        acc.append(v);
    }
    return sorted(acc);
}

def disposition_counts(g: FeedbackGraph) -> dict[str, int] {
    counts: dict[str, int] = {};
    for fid in g.items {
        fb = g.items[fid];
        disp = fb.disposition;
        if disp in counts {
            counts[disp] = counts[disp] + 1;
        } else {
            counts[disp] = 1;
        }
    }
    return counts;
}

def planning_baseline() -> dict[str, str] {
    base: dict[str, str] = {};
    base["version"] = "v0.1.3";
    base["commit"] = "9a835a28845f3cc8bdbf9bd98bf503fdf351254a";
    return base;
}
