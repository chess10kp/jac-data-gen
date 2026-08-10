"""Clip an integer RGB component to the inclusive range 0-255."""
def _normalize_integer_rgb(value: int) -> int {
    return 0 if value < 0 else 255 if value > 255 else value;
}