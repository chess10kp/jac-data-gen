"""Converts a seconds value in float to the number of ms as an integer."""
def _secs_to_ms(value: float) -> int {
    return int(round(value * 1000.0));
}