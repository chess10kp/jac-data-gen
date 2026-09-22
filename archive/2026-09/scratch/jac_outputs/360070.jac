"""Make ranking according to fitness."""
def _make_rank(fitness: list[float]) -> list[int] {
    rank_dict = {i: _fitness for (i, _fitness) in enumerate(fitness)};
    return [k for (k, _) in sorted(rank_dict.items(), key=lambda (x: tuple[int, float]) { x[1]; })];
}