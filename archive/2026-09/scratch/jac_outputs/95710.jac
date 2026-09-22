"""
Computes and returns the derivative of a polynomial function. If the
derivative is 0, returns (0.0,).
"""
def compute_deriv(poly: tuple[float, ...]) -> tuple[float, ...] {
    index = 0.0;
    der = [];
    for mono in poly {
        mono_der = index * mono;
        if index > 0.0 {
            der.append(mono_der);
        }
        index += 1.0;
    }
    return tuple(der);
}