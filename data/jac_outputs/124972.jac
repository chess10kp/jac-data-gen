"""
Convert rotational constants in units of MHz to
Inertia, in units of amu A^2.

The conversion factor is adapted from:
Oka & Morino, JMS (1962) 8, 9-21
This factor comprises h / pi^2 c.
"""
def rotcon2pmi(rotational_constant: float) -> float {
    return 1 / (rotational_constant / 134.901);
}