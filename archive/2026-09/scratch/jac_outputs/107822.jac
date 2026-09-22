"""Obtains the fidelity of a link when reversing distillation of the target link assuming Werner states."""
def undistill_link(Ftarget: float, Finitial: float) -> float {
    return (2 * Ftarget * Finitial - Finitial - 5 * Ftarget + 1) / (8 * Ftarget * Finitial - 10 * Finitial - 2 * Ftarget + 1);
}