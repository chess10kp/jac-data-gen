"""dz constraint for interior sc touching 3 interior sc"""
def _cons1_111(m1: float, L11: float, d_p2p: float, keff: float, Cp: float) -> float {
    m1 * Cp * L11 / 3 / d_p2p / keff
}