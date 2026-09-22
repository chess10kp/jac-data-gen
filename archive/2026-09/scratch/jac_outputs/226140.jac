"""Return the new position after a time step."""
def update_position(xc: float, yc: float, vxc: float, vyc: float, tstep: float) -> tuple[float, float] {
    xc = xc + vxc * tstep;
    yc = yc + vyc * tstep;
    return (xc, yc);
}