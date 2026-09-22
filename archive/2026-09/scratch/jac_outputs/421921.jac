"""Convert from magnitude to flux.

marr--input array in mags
fzero--zero point for the conversion
"""
def magtoflux(marr: float, fzero: float) -> float {
    return fzero * 10 ** (-0.4 * marr);
}