"""Reduce for top similars."""
def top_similars_reduce(data: tuple[float, object]) -> tuple[float, object] {
    (sim, item) = data;
    return (sim, item);
}