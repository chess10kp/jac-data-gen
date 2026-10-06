# graph/nodes.jac — [SHARED] Pure node declarations.

node FileNode {
    has path: str;
    has content: str = "";
    has language: str = "jac";
    has risk_score: int = 0;
    has is_test: bool = False;
}

node FindingNode {
    has walker_type: str;
    has severity: str;
    has description: str;
    has evidence: str;
    has line_number: int = 0;
}

node PRAnalysisNode {
    has pr_url: str;
    has created_at: str;
    has verdict: dict = {};
}

node DependencyNode {
    has package_name: str;
    has normalized_name: str;
    has ecosystem: str;
    has version_spec: str = "";
}

node DocumentationNode {
    has path: str;
    has title: str = "";
}

node TestNode {
    has path: str;
    has module_guess: str = "";
}

node GhostwatchIncidentNode {
    has dedupe_key: str;
    has repo_full_name: str;
    has commit_sha: str;
    has manifest_path: str;
    has dependency_name: str;
    has status: str;
    has risk_level: str;
    has created_at: str;
    has updated_at: str;
    has dependency_version: str = "";
    has rule_codes: list = [];
    has sandbox_result: dict = {};
    has behavioral_trace: dict = {};
    has fix_pr_url: str = "";
    has fix_branch_name: str = "";
    has next_escalation_at: str = "";
    has alert_state: str = "";
}

node GapAnalysisNode {
    has merge_commit_sha: str;
    has created_at: str;
    has suggestions: list = [];
}

node IssueIntelligenceNode {
    has repo_full_name: str;
    has issues_fetched_at: str;
    has issues_snapshot: list = [];
    has issues_fingerprint: str = "";
    has digest: dict = {};
    has digest_fetched_at: str = "";
}
