"""Helper function for choose_a_pick."""
def key_for_min(pick: tuple[tuple, tuple[object, int]]) -> int {
    return pick[1][1];
}