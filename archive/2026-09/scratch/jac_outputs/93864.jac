"""Increment in the same direction as the valence."""
def increment(valence: float, increment: float) -> float {
    if valence == 0.0 {
        return valence;
    } elif valence > 0 {
        return valence + increment;
    } else {
        return valence - increment;
    }
}