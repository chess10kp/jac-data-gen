"""
    Estimation of time to go from position_0 to position_1
    FIXME : Does not take into account forbidden angle, and
            rotation direction neither (shortest path is chosen)
            works with
    """
def pt_time_estimation(
    position_0: Any,
    position_1: Any,
    pan_speed: Any = 22.5,
    tilt_speed: Any = 6.5,
    unit: Any = 0.01
) -> object {
    if ((position_0 is None) or (position_1 is None)) {
        return;
    }
    (pan0, tilt0) = position_0;
    (pan1, tilt1) = position_1;
    return (
        unit
        * max((abs((pan1 - pan0)) / pan_speed), (abs((tilt1 - tilt0)) / tilt_speed))
    );
}