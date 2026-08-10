"""Calculate binary component positions at perihelion with COM at origin."""
def calcPositions(M: float = 1, a: float = 1, e: float = 0, p: float = 0.5) -> tuple[float, float] {
    m1 = p * M;
    m2 = M - m1;
    a1 = m2 / M * a;
    a2 = m1 / M * a;
    x1 = a1 * (1 - e * e) / (1 + e);
    x2 = -a2 * (1 - e * e) / (1 + e);
    return (x1, x2);
}