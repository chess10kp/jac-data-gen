"""Convert a mapping of distinct quantities to a mapping of proportions of the total quantity."""
def scale_to_total(value: dict[str, int | float]) -> dict[str, float] {
    total = float(sum(value.values()));
    return {k: v / total for (k, v) in value.items()};
}