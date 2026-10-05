"""Agency engine data models for Trace."""

enum AutonomyLevel {
    OBSERVE,
    SUGGEST,
    DRAFT,
    ACT_APPROVED,
    AUTOMATE
}

node AgencyPolicy {
    has domain: str = "";
    has autonomy_level: AutonomyLevel = AutonomyLevel.OBSERVE;
    has constraints: list[str] = [];
    has total_actions: int = 0;
}

node PendingAction {
    has action_type: str = "";
    has description: str = "";
    has confidence: float = 0.0;
    has domain: str = "";
    has created_at: str = "";
    has approved: bool = False;
    has executed: bool = False;
}
