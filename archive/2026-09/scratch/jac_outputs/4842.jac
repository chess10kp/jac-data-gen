"""Mie pair potential."""
def mie(r: float, eps: float, sig: float, m: float = 12, n: float = 6) -> float {
    prefactor = m / (m - n) * (m / n) ** (n / (m - n));
    return prefactor * eps * ((sig / r) ** m - (sig / r) ** n);
}