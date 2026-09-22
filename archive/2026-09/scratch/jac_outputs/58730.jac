"""Return the cross product of two vectors, a x b."""
def Cross3(a: tuple[float, float, float], b: tuple[float, float, float]) -> tuple[float, float, float] {
    (ax, ay, az) = a;
    (bx, `by, bz) = b;
    return (
        ay * bz - az * `by,
        az * bx - ax * bz,
        ax * `by - ay * bx
    );
}