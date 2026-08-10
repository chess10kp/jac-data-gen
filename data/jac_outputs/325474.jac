"""P velocity boost control."""
def boost_velocity(vel: int, dvel: int, lboost: int = 0) -> bool {
    rel_vel = dvel - vel - lboost * 5;
    if vel < 1400 {
        threshold = 800 if dvel < 0 else 250;
    } else {
        threshold = 30;
    }
    return rel_vel > threshold;
}