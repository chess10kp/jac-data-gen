"""
    As :py:func:`E_MurnV` but input parameters are given as a single list
    *a=[a0,a1,a2,a3]* and it returns the pressure not the energy from the EOS.
    """
def P_Murn(V: Any, a: Any) -> object {
    return ((a[2] / a[3]) * (pow((a[1] / V), a[3]) - 1.0));
}