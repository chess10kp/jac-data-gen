"""Marino et al. 2008 A&A 490, 625 (from Gratton et al. 1996)."""
def logg_to_vt_M08(logg: float) -> float {
    2.22 - 0.322 * logg
}