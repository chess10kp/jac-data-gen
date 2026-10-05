"""Decision engine data models for Trace."""

enum RiskTolerance {
    CONSERVATIVE,
    MODERATE,
    AGGRESSIVE
}

node DecisionRecord {
    has situation: str = "";
    has options: list[str] = [];
    has chosen: str = "";
    has outcome: str = "";
    has regret_level: float = 0.0;
    has domain: str = "";
    has timestamp: str = "";
}

node DecisionProfile {
    has risk_tolerance: RiskTolerance = RiskTolerance.MODERATE;
    has values_hierarchy: list[str] = [];
    has avg_decision_speed: float = 0.0;
    has self_defeating_patterns: list[str] = [];
}
