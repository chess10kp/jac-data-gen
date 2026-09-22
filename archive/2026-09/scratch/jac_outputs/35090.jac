"""Compute the center of the DTM in pixel space."""
def getcamera_target(minextents: tuple[float, float, float], maxextents: tuple[float, float, float]) -> tuple[float, float, float] {
    xcenter = (maxextents[0] - minextents[0]) / 2.0;
    ycenter = (maxextents[1] - minextents[1]) / 2.0;
    zcenter = (maxextents[2] - minextents[2]) / 2.0;
    return (xcenter, ycenter, zcenter);
}