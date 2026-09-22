"""
    Return the first (year, coefficient) tuple in targets with coefficient != 0.
    """
def firstTarget(targets: list[tuple[int, int | float]]) -> tuple[int, int | float] | None {
    targets.sort(key=lambda (tup: tuple[int, int | float]) { tup[0]; });
    for (year, coefficient) in targets {
        if coefficient {
            return (year, coefficient);
        }
    }
}