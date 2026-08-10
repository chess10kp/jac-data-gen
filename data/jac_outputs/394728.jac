"""Sphere function defined as:
    $$ f(x) = \sum_{i=1}^{n} x_i^{2} $$
    with a search domain of $-5.12 < x_i < 5.12, 1 \leq i \leq n$.
    The global minimum is at $f(x_1, ..., x_n) = f(0, ..., 0) = 0.
    It is continuous, convex and unimodal.
    """
def sphere(ind: list[float]) -> tuple[float] {
    return (sum((x ** 2.0) for x in ind),);
}