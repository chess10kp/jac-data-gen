"""Converts from given geometric altitude to geopotential one."""
def geometric_to_geopotential(z: float, r0: float) -> float {
    r0 * z / (r0 + z)
}