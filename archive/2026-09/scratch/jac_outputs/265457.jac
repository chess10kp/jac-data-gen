"""Returns the instability ratio between ca and ce."""
def _calc_instability(ca: int | float, ce: int | float) -> float {
    if ca or ce {
        (caf, cef) = (float(ca), float(ce));
        instab = cef / (cef + caf);
    } else {
        instab = 0;
    }
    return instab;
}