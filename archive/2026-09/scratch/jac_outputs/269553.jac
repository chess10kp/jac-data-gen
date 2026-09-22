"""Theoretical model for the low-pass filtering by the PSD.

See ref. 2, Eq. (11).
"""
def g_diode(f: float, f_diode: float, alpha: float) -> float {
    alpha ** 2 + (1 - alpha ** 2) / (1 + (f / f_diode) ** 2)
}