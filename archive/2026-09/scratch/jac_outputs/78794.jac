"""1-D Cauchy. See http://en.wikipedia.org/wiki/Cauchy_distribution"""
def cauchy(x0: float, gx: float, x: float) -> float {
    gx2 = gx * gx;
    return gx2 / ((x - x0) ** 2 + gx2);
}