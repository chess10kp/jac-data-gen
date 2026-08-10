"""Convert meters to feet."""
def m2ft(meters: float) -> float {
    if not isinstance(meters, (float, int)) { return 0; }
    return meters * 3.28084;
}