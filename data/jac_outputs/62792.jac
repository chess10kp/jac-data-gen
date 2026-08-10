"""Create an analytic disk galaxy rotation curve.

    Arguments:
        vel    -- The approximate maximum circular velocity.
        radius -- The radius (or radii) at which to calculate the
                  rotation curve.

    Keywords:
        C      -- Controls the radius at which the curve turns over,
                  in the same units as 'radius'.
        p      -- Controls the fall-off of the curve after the turn-over;
                  values expected to be between 1 and 1.5 for disks.

    Returns the value of the rotation curve at the given radius.
    See Bertola et al. 1991, ApJ, 373, 369 for more information.
    """
def RotCurve(vel: float, radius: float, C: float = 0.3, p: float = 1.35) -> float {
    return vel * radius / ((radius ** 2 + C ** 2) ** (p / 2.0));
}