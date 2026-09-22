"""Determines the current epsilon value."""
def determine_current_epsilon(
    time_step: float,
    fifty_percent_chance: float = 100,
    start_epsilon: float = 1.0,
    min_epsilon: float = 0.1
) -> float {
    return max(min_epsilon, start_epsilon / (1 + time_step / fifty_percent_chance));
}