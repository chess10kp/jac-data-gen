"""A neighbor of x is either 2*x or x+3."""
def step(x: int) -> list[int] {
    return [x + 3, 2 * x];
}