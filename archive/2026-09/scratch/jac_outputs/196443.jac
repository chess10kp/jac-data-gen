""" return alpha based on z depth """
def zalpha(z: float, zmin: float, zrng: float, a_min: float = 0) -> float {
    a_min + (1 - a_min) * (z - zmin) / zrng
}