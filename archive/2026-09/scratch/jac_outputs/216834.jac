"""Adjust steering velocity based on angle and velocity constraints."""
def steering_constraint(
    steering_angle: float,
    steering_velocity: float,
    s_min: float,
    s_max: float,
    sv_min: float,
    sv_max: float
) -> float {
    if (steering_angle <= s_min and steering_velocity <= 0)
        or (steering_angle >= s_max and steering_velocity >= 0) {
        steering_velocity = 0.0;
    } elif steering_velocity <= sv_min {
        steering_velocity = sv_min;
    } elif steering_velocity >= sv_max {
        steering_velocity = sv_max;
    }
    return steering_velocity;
}