"""convert a pixel number into a surface in hectar using the provided resolution (res in meters)"""
def to_hectar(x: int, resx: float, resy: float) -> float {
    return x * resx * resy / 10000;
}