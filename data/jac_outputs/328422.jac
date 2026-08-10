"""Perm function 0, D, BETA defined as:
    $$ f(x) = \sum_{i=1}^n (\sum_{j=1}^n (j+\beta) (x_j^i - \frac{1}{j^i}) )^2$$
    with a search domain of $-n < x_i < n, 1 \leq i \leq n$.
    The global minimum is at $f(x_1, ..., x_n) = f(1, 2, ..., n) = 0.
    """
def perm0db(ind: list[float], beta: float = 10.0) -> tuple[float] {
    return (
        sum(
            (
                sum(
                    (
                        (j + 1.0 + beta)
                        * (
                            ind[j] ** float(i + 1)
                            - 1.0 / (float(j + 1) ** float(i + 1))
                        )
                    ) for j in range(len(ind))
                )
                ** 2.0
            ) for i in range(len(ind))
        ),
    );
}