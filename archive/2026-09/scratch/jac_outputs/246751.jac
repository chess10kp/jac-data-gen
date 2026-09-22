"""Scale the input value from 0-255 to 0-100."""
def scale_to_100(value: int) -> float {
    return max(0.0, min(100.0, (value * 100.0) / 255.0));
}