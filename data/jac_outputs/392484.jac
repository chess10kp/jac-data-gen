"""
From real coordinates get rendered coordinates.
"""
def scale(x: float, range: list[float] | tuple[float, float], drange: list[float] | tuple[float, float]) -> float {
    (rx1, rx2) = (float(range[0]), float(range[1]));
    (sx1, sx2) = (float(drange[0]), float(drange[1]));
    return (sx2 - sx1) * (x - rx1) / (rx2 - rx1) + sx1;
}