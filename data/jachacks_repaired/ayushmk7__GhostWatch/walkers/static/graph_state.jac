# walkers/static/graph_state.jac
# GraphStateWalker: returns full graph topology + latest PRAnalysisNode for frontend.
# Called by the frontend on load and every 5s poll.
# Implementation: walkers/static/impl/graph_state.impl.jac

import from graph.nodes { FileNode, PRAnalysisNode, GhostwatchIncidentNode, GapAnalysisNode }

walker:pub GraphStateWalker {
    has nodes_data: list = [];
    has edges_data: list = [];
    has has_graph: bool = False;
    has latest_pr: dict | None = None;
    has latest_incident: dict | None = None;
    has latest_gap: dict | None = None;
    has reports: list = [];

    can fetch with Root entry;
    can collect_file with FileNode entry;
    can collect_pr with PRAnalysisNode entry;
    can collect_incident with GhostwatchIncidentNode entry;
    can collect_gap with GapAnalysisNode entry;
    can finish with Root exit;

    def _digest_open_issues(compact_outline: str) -> dict by llm;
}

sem GraphStateWalker._digest_open_issues = "You are assisting a lead maintainer triaging GitHub issues. Input is a tab-separated list: issue_number, title, comma_separated_labels (one issue per line). Return ONLY a JSON object with keys: summary (string, 2-4 sentences on overall backlog health), recommended (array of objects with issue_number int, title string, reason string — highest-impact items to fix soon), clusters (array of objects with name string, issue_numbers array of int, note string — group the rest: triage, docs, CI, blocked, etc.). No markdown fences."; # jac:ignore[W2001]
