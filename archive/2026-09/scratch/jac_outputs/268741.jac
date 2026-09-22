"""Eq 1.12 from Fedkiw Osher book."""
def UnitStep(x: float) -> int {
    return 1 if x > 0 else 0;
}