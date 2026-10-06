# objects/verdict.jac — Shared data objects for System 1 and System 2.

obj SecurityFinding {
    has severity: str;
    has description: str;
    has line_number: int;
    has evidence: str;
    has recommendation: str;
}

sem SecurityFinding.severity = "critical, high, medium, or low — how dangerous this issue is";
sem SecurityFinding.description = "concise human-readable description of the security issue";
sem SecurityFinding.line_number = "line number where the issue occurs, 0 if not line-specific";
sem SecurityFinding.evidence = "exact code snippet or path demonstrating the issue";
sem SecurityFinding.recommendation = "specific actionable fix for this issue";

obj CompatibilityIssue {
    has api_name: str;
    has issue_type: str;
    has description: str;
    has affected_callers: list[str];
}

sem CompatibilityIssue.api_name = "name of the API function or class that has a compatibility issue";
sem CompatibilityIssue.issue_type = "breaking_change, deprecation, interface_mismatch, or type_change";
sem CompatibilityIssue.description = "what the compatibility issue is and why it matters";
sem CompatibilityIssue.affected_callers = "list of file paths that call this API and will break";

obj ContributorSuggestion {
    has title: str;
    has description: str;
    has difficulty: str;
    has file_path: str;
    has suggestion_type: str;
}

sem ContributorSuggestion.title = "concise issue title suitable for a GitHub issue";
sem ContributorSuggestion.description = "two to three sentence description of what needs to be done";
sem ContributorSuggestion.difficulty = "good-first-issue, intermediate, or advanced";
sem ContributorSuggestion.file_path = "which file this suggestion targets";
sem ContributorSuggestion.suggestion_type = "missing_tests, missing_docs, incomplete_feature, or missing_example";

obj VerdictObject {
    has overall_risk: str;
    has risk_score: int;
    has affected_node_count: int;
    has blast_radius_summary: str;
    has recommendation: str;
    has security_findings: list = [];
    has compatibility_issues: list = [];
    has traversal_paths: dict = {};
}

sem VerdictObject.overall_risk = "critical, high, medium, low, or clean — the overall PR risk level";
sem VerdictObject.risk_score = "0 to 100 numeric risk score where 100 is most dangerous";
sem VerdictObject.affected_node_count = "total number of graph nodes affected by this PR change";
sem VerdictObject.blast_radius_summary = "one paragraph summary of blast radius analysis results";
sem VerdictObject.recommendation = "one sentence recommendation for the maintainer reviewing this PR";
sem VerdictObject.traversal_paths = "dict with keys security, compatibility, blast_radius — each a list of node jids visited";
