"""

    Convert from dynamic to kinematic viscosity.

    Parameters
    ----------
    dyn: ndarray, scalar
        The dynamic viscosity of the lubricant.
    density: ndarray, scalar
        The density of the lubricant.

    Returns
    -------
    kin: ndarray, scalar
        The kinematic viscosity of the lubricant.

    """
def dyn2kin(dyn: Any, density: Any) -> object {
    kin = dyn / density;
    return kin;
}