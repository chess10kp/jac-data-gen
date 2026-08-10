"""
    Returns the R56Q-RPR reversal potential (in mV) for the given integer index
    ``cell``.
    """
def ek_R56Q_RPR(cell: int) -> float {
    reversal_potentials = {1: -92.2, 2: -89.0, 3: -90.1, 4: -95.0, 5: -93.1, 6: -93.4};
    return reversal_potentials[cell];
}