"""Bound speed to the limits allowed by crickit motor.throttle."""
def boundMotorSpeed(speed: float) -> float {
    if speed < -1 {
        return -1;
    }
    if speed > 1 {
        return 1;
    }
    return speed;
}