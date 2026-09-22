"""Calculate norm of vector [x, y, z]."""
def norm3d(x: float, y: float, z: float) -> float {
    return (x * x + y * y + z * z) ** 0.5;
}