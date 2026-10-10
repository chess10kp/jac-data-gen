"""GHOST BOARD — Shared Models & Constants.

Centralizing the data structures for both Server and Client codespaces.
"""

# -----------------------------------------------------------------------------
# Enums & Constants
# -----------------------------------------------------------------------------

enum ExecutiveStatus: str {
    ACTIVE = "ACTIVE",
    PROCESSING = "PROCESSING",
    SYNC = "SYNC",
    STANDBY = "STANDBY",
    CRISIS = "CRISIS"
}

enum Severity: str {
    CRITICAL = "CRITICAL",
    HIGH = "HIGH",
    ELEVATED = "ELEVATED",
    WARNING = "WARNING",
    INFO = "INFO"
}

# -----------------------------------------------------------------------------
# Data Nodes (The Knowledge Graph)
# -----------------------------------------------------------------------------

node Executive {
    has id: str;
    has name: str;
    has role: str;
    has color: str;
    has confidence: float = 100.0;
    has workflow_load: float = 0.0;
    has reasoning: str = "Awaiting deployment";
    has objective: str = "Monitoring system health";
    has status: ExecutiveStatus = ExecutiveStatus.STANDBY;
    has is_thinking: bool = False;
}

node SystemMetrics {
    has system_load: float = 28.4;
    has net_latency: int = 14;
    has sec_integrity: float = 99.9;
    has active_workflows: int = 1248;
    has ai_proc_load: float = 82.1;
    has global_sync: float = 99.8;
    has data_throughput: float = 1.2;
    has latest_event: str = "NEURAL_SYNC_COMPLETE";
    has uptime_seconds: int = 5335924;
}

node Crisis {
    has id: str;
    has severity: Severity;
    has message: str;
    has triggered_at: str;
}

node IntelligenceReport {
    has summary: str;
    has crisis_label: str;
    has operational_risk: str;
    has infrastructure_status: str;
    has recommendations: list[str];
    has generated_at: str;
}

# -----------------------------------------------------------------------------
# Edges
# -----------------------------------------------------------------------------

edge manages;
edge reports_to;
edge monitoring;
