"""Returns the top one if it is above threshold."""
def print_belief_state_woz_requestables(
    curr_values: list[object],
    distribution: list[float],
    threshold: float
) -> list[object] {
    return [value for (idx, value) in enumerate(curr_values) if distribution[idx] >= threshold];
}