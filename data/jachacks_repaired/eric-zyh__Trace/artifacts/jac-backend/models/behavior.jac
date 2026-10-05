"""Behavior and timing engine data models for Trace."""

enum EnergyLevel {
    PEAK,
    HIGH,
    MODERATE,
    LOW,
    DEPLETED
}

node BehaviorProfile {
    has productivity_hours: list[float] = [];
    has procrastination_triggers: list[str] = [];
    has response_time_avg: float = 0.0;
    has current_energy: EnergyLevel = EnergyLevel.MODERATE;
    has wake_time: str = "07:00";
    has sleep_time: str = "23:00";
}

node InterventionRecord {
    has intervention_type: str = "";
    has scheduled_time: str = "";
    has acted_on: bool = False;
    has action_latency: float = 0.0;
    has context: str = "";
}

node HabitLoop {
    has cue: str = "";
    has routine: str = "";
    has reward: str = "";
    has frequency_days: float = 1.0;
    has success_rate: float = 0.0;
    has streak: int = 0;
}
