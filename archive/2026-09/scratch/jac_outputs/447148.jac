"""Calculates the new temperature per iteration using a cauchy progression."""
def cauchy_cooling_sequence(initial_t: float, it: int) -> float {
    return initial_t / (1 + it);
}