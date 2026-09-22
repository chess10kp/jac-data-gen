"""
    Function initializes krls dictionary.

    Returns:
        dAldKRLS (dictionary): Python dictionary which contains all the data of the current KRLS algorithm.
    """
def `init(
    strKernel: str,
    iKernelPar: float = 1,
    iALDth: float = 0.0001,
    iMaxDict: float = 1000.0
) -> dict[str, float | str | int] {
    dAldKRLS = {};
    dAldKRLS['iALDth'] = iALDth;
    dAldKRLS['iMaxDt'] = iMaxDict;
    dAldKRLS['strKernel'] = strKernel;
    dAldKRLS['iKernelPar'] = iKernelPar;
    dAldKRLS['bInit'] = 0;
    return dAldKRLS;
}