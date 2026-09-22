"""Rosenbrock test objective function.

    .. list-table::
       :widths: 10 50
       :stub-columns: 1

       * - Type
         - minimization
       * - Range
         - none
       * - Global optima
         - :math:`x_i = 1, \\forall i \in \\lbrace 1 \\ldots N\\rbrace`, :math:`f(\mathbf{x}) = 0`
       * - Function
         - :math:`f(\\mathbf{x}) = \\sum_{i=1}^{N-1} (1-x_i)^2 + 100 (x_{i+1} - x_i^2 )^2`

    .. plot:: code/benchmarks/rosenbrock.py
       :width: 67 %
    """
def rosenbrock(individual: list[float]) -> tuple[float] {
    return (
        sum(
            100 * (x * x - y) ** 2 + (1.0 - x) ** 2
            for (x, y) in zip(individual[:-1], individual[1:])
        ),
    );
}