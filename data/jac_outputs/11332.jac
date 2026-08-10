"""Steps between two values."""
def steps(current: float, target: float, max_steps: int) -> int {
    if current < 0 or current > 1.0 {
        raise ValueError("current value %s is out of bounds (0.0-1.0)", current);
    }
    if target < 0 or target > 1.0 {
        raise ValueError("target value %s is out of bounds (0.0-1.0)", target);
    }
    return int(abs(current * max_steps - target * max_steps));
}