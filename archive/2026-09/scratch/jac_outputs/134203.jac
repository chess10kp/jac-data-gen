"""Get the current state from a state probability vector."""
def get_current_state(state_vector: list[int]) -> int {
    return state_vector.index(1);
}