"""Validates the distance of an object."""
def validate_distance(distance: float) -> float {
    if distance < 0 {
        raise ValueError("The distance must be zero or positive.");
    }
    return distance;
}