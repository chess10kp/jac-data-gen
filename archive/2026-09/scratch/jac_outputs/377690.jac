"""Calculates the distance traveled given initial velocity, acceleration, and time."""
def distance_helper(initial_velocity: int, acceleration: int, time: int) -> float {
    return initial_velocity * time + 0.5 * acceleration * time ** 2;
}