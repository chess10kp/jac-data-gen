"""Returns velocities from a perfectly elastic collision between masses m1 and m2."""
def Elastic(m1: float, m2: float, v1: float, v2: float) -> tuple[float, float] {
    vp2 = (m2 * v2 + m1 * (2.0 * v1 - v2)) / (m1 + m2);
    vp1 = vp2 + v2 - v1;
    return (vp1, vp2);
}