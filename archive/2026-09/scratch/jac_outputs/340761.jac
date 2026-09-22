"""Solve quadratic equation."""
def delta(
    t1: float,
    tauv: float,
    taue: float,
    tauev: float,
    t0c: float,
    tzc: float,
    txc: float,
    dzi: float,
    dxi: float,
    dz2i: float,
    dx2i: float,
    vzero: float,
    vref: float,
    sgntz: float,
    sgntx: float
) -> float {
    ta = tauev + taue - tauv;
    tb = tauev - taue + tauv;
    apoly = dz2i + dx2i;
    bpoly = 4.0 * (sgntx * txc * dxi + sgntz * tzc * dzi) - 2.0 * (ta * dx2i + tb * dz2i);
    cpoly = ta ** 2.0 * dx2i + tb ** 2.0 * dz2i - 4.0 * (sgntx * txc * dxi * ta + sgntz * tzc * dzi * tb) + 4.0 * (vzero ** 2.0 - vref ** 2.0);
    dpoly = bpoly ** 2.0 - 4.0 * apoly * cpoly;
    return 0.5 * (dpoly ** 0.5 - bpoly) / apoly + t0c if dpoly >= 0.0 else t1;
}