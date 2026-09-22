"""Centripetal force keeping mass m at velocity v on circular path radius r."""
def centripetal_force(m: float, v: float, r: float) -> float {
    return m * v ** 2 / r;
}