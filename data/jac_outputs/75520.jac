"""Compute mass lost during a GW merger between two BHs. Expression from
    Tichy & Marronetti 2008."""
def merger_mass_loss(q: float, a_1: float, a_2: float) -> float {
    v = q / (1 + q) ** 2;
    0.2 * v + 0.208 * v ** 2 * (a_1 + a_2)
}