"""Antiderivative of the Birch Murnaghan E(V)."""
def antiderE(V0: float, B0: float, B0pr: float, V: float) -> float {
    return (
        9
        * B0
        * V0
        * (
            -((-6 + B0pr) * V) - (((-4 + B0pr) * (V0 ** 2)) / V)
            + (3 * (-14 + (3 * B0pr)) * V0 * ((V0 / V) ** (1 / 3)))
            + (3 * (-16 + (3 * B0pr)) * V * ((V0 / V) ** (2 / 3)))
        )
        / 16
    );
}