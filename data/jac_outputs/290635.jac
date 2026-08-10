"""Hill-Langmuir receptor occupation equation.

    Args:
        l (float, numpy.array): The input concentration of an ligand in
            concentration units.
        kd (float): The ligand-receptor dissociation constant (or its
            effective value) in concentration units.
                Bounds fot fitting: 0 <= kd <= inf

    Returns:
        float, numpy.array : The fractional receptor occupation for the given
            ligand concentration; unitless, range [0,1].
    """
def hill_langmuir_equation(l: Any, kd: Any) -> object {
    return (l / (l + kd));
}