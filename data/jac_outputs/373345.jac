"""Bandwidth of an Equivalent Rectangular Bandwidth (ERB)."""
def erb_bandwidth(fc: float) -> float {
    return 24.7 + fc / 9.265;
}