"""angular derivative in respect to y when phi = arctan2(y, x)"""
def d_phi_dy(x: float, y: float) -> float {
    return x / (x ** 2 + y ** 2);
}