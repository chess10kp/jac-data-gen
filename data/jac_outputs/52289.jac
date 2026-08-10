"""Multiply each entry of a vector by a scalar."""
def vmul(vect: list[int | float], s: int | float) -> list[int | float] {
    [x * s for x in vect]
}