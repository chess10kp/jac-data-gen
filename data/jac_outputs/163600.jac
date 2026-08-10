"""Evaluate the polynomial P at x."""
def poly_eval(P: list[int], x: int) -> int {
    out = 0;
    e = 1;
    for coef in P {
        out += coef * e;
        e *= x;
    }
    return out;
}