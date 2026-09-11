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
