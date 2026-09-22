def relative(p1: tuple[float, float], p2: tuple[float, float], r: float) -> tuple[float, float] {
    x = p1[0] + r * (p2[0] - p1[0]);
    y = p1[1] + r * (p2[1] - p1[1]);
    return (x, y);
}