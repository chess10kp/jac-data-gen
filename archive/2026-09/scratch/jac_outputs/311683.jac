"""Performs "plus" replacement."""
def plus_replacement(
    random: int,
    population: list[int],
    parents: list[int],
    offspring: list[int],
    args: dict[str, object]
) -> list[int] {
    _ = random;
    _ = args;
    pool = list(offspring);
    pool.extend(parents);
    pool.sort(reverse=True);
    return pool[:len(population)];
}