"""Choose a reasonable DMstep by setting max smearing across BW to equal dt."""
def guess_DMstep(dt: float, BW: float, fctr: float) -> float {
    return dt * 0.0001205 * (fctr ** 3.0) / BW;
}