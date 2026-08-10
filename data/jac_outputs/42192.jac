"""Homogenize, or project back to the w=1 plane by scaling all values by w."""
def homo(a: list[float]) -> list[float | int] {
    return [a[0] / a[3], a[1] / a[3], a[2] / a[3], 1];
}