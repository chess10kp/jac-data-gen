"""SARIF directory export dedup, lifted to OSP.

Report sources become Report nodes carrying their findings; suite/matrix
references become typed Includes edges. The shared visited set the issue
demands becomes one claim map passed by reference into every spawned
flood -- each report contributes its findings exactly once no matter how
many expansion paths reach it. Revisits are `skip`ed explicitly: jac
0.36.1 walkers do not dedupe on cyclic or diamond reference graphs.
Ref: richinmrudul/agentguard#182
"""
node Report {
    has rid: str;
    has findings: list[str];
}
edge Includes {}  # aggregate -> referenced child report

"""Loader handle: report ids resolve through this lookup map."""
obj ExportSource {
    has reports: dict[str, Report];
    has ids: list[str];

    def resolve(rid: str) -> Report | None {
        return self.reports.get(rid);
    }
}

"""Deterministic fresh-graph builder; creation order = fixture order."""
def load_reports(reports: dict, references: list) -> ExportSource {
    src = ExportSource(reports={}, ids=[]);
    for rid in reports.keys() {
        r = Report(rid=rid, findings=list(reports[rid]));
        root ++> r;
        src.reports[rid] = r;
        src.ids.append(rid);
    }
    for (parent, child) in references {
        src.reports[parent] +>:Includes:+> src.reports[child];
    }
    return src;
}

walker FindingFlood {
    # Cycle policy / canonical-source rule: one SHARED claimed map across
    # every spawn chain; a report reached again is skipped entirely.
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];

    can step_report with Report entry {
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        for f in here.findings {
            self.collected.append(here.rid + ":" + f);
        }
        visit [->:Includes:->];
    }
}

"""Findings of every report reachable from any root, deduplicated.

Returns a sorted list of ``report_id:finding`` strings; each report
contributes exactly once regardless of how many paths reach it.
"""
def export_findings(src: ExportSource, root_ids: list) -> list[str] {
    claimed: dict[str, bool] = {};
    collected: list[str] = [];
    roots = sorted(root_ids);
    for rid in roots {
        start = src.resolve(rid);
        if start is None or rid in claimed {
            continue;
        }
        start spawn FindingFlood(claimed=claimed, collected=collected);
    }
    return sorted(collected);
}

"""Distinct reports contributing to the export."""
def report_count(src: ExportSource, root_ids: list) -> int {
    w_flood_claimed: dict[str, bool] = {};
    roots = sorted(root_ids);
    for rid in roots {
        start = src.resolve(rid);
        if start is None or rid in w_flood_claimed {
            continue;
        }
        start spawn FindingFlood(claimed=w_flood_claimed, collected=[]);
    }
    return len(w_flood_claimed.keys());
}


test "shared child emitted once across both aggregates" {
    src = load_reports({"suite": ["S:rule1"], "matrix": ["M:rule2"], "run_a": ["A:rule3", "A:rule4"], "run_b": ["B:rule5"]}, [("suite", "run_a"), ("matrix", "run_a"), ("suite", "run_b")]);
    assert export_findings(src, ["suite", "matrix", "run_a"]) == ["matrix:M:rule2", "run_a:A:rule3", "run_a:A:rule4", "run_b:B:rule5", "suite:S:rule1"];
    assert report_count(src, ["suite", "matrix", "run_a"]) == 4;
}

test "diamond reference tree stays duplicate-free" {
    tree = load_reports({"top": ["T:0"], "left": [], "right": [], "leaf": ["L:1"]}, [("top", "left"), ("top", "right"), ("left", "leaf"), ("right", "leaf")]);
    assert export_findings(tree, ["top"]) == ["leaf:L:1", "top:T:0"];
    assert report_count(tree, ["top"]) == 4;
}

test "direct single-aggregate enrichment intact" {
    single = load_reports({"only": ["O:9"]}, []);
    assert export_findings(single, ["only"]) == ["only:O:9"];
    assert report_count(single, ["only"]) == 1;
}

test "reference cycle terminates without truncation" {
    loop = load_reports({"m": ["M:1"], "n": ["N:2"]}, [("m", "n"), ("n", "m")]);
    assert export_findings(loop, ["m"]) == ["m:M:1", "n:N:2"];
    assert report_count(loop, ["m"]) == 2;
}
