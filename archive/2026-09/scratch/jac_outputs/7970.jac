"""derivative of d(y/r)/dx, equivalent to second order derivatives dr_dxy"""
def d_y_diffr_dx(x: float, y: float) -> float {
    return -x * y / (x ** 2 + y ** 2) ** (3 / 2.0);
}