"""move blank space down on the board and return new state."""
def down(state: list[int]) -> list[int] | None {
    new_state = state[:];
    index = new_state.index(0);
    if index not in (6, 7, 8) {
        temp = new_state[index + 3];
        new_state[index + 3] = new_state[index];
        new_state[index] = temp;
        return new_state;
    }
    return None;
}