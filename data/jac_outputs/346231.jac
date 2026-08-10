"""
    Determines guide field ratio, the ratio of the PIL-parallel component of
    magnetic field to the PIL-perpendicular component, a proxy for the magnetic
    shear.
    """
def gfrcalc_alt(guide: object, distneg_med: object, distpos_med: object) -> object {
    guide / (distneg_med + distpos_med)
}