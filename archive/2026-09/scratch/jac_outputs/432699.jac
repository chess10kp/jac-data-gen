"""Returns a binary vector that indicates whether individuals are infected."""
def _infection_indicator(health_states: list[int], infected_state_index: int) -> list[int] {
    [int(state == infected_state_index) for state in health_states]
}