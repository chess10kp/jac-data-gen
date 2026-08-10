"""The non-cold dark amtter transfer function as in Murgia(2018) and Stucker (2021)"""
def transfer_ncdm(k: float, alpha: float, beta: float, gamma: float = 5.0) -> float {
    return (1.0 + (alpha * k) ** beta) ** -gamma;
}