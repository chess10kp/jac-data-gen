"""DepGraph OSP node definitions."""

node InvestigationSession {
    has repo_url: str;
    has ecosystem: str = "npm";
    has status: str = "pending";
    has started_at: str = "";
    has package_count: int = 0;
}

node Package {
    has name: str;
    has version: str;
    has ecosystem: str = "npm";
    has is_direct: bool = False;
    has depth: int = 0;
    has cvss_score: float = 0.0;
    has has_critical_cve: bool = False;
    has analysis_status: str = "pending";
}

node CVE {
    has cve_id: str;
    has cvss_score: float = 0.0;
    has severity: str = "UNKNOWN";
    has description: str = "";
    has fixed_version: str = "";
}

node UsageContext {
    has called_from_modules: list[str] = [];
    has risk_surface: str = "unknown";
    has is_reachable_in_prod: bool = True;
    has call_chain: list[str] = [];
}

node RemediationPlan {
    has package_name: str;
    has current_version: str;
    has target_version: str;
    has breaking_changes: list[str] = [];
    has confidence: float = 0.0;
    has status: str = "proposed";
}
