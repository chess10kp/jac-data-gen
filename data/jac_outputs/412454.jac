"""Returns the sorted values of a dictionary as a list."""
def sorted_values(x: dict[str, int]) -> list[int] {
    return [x[k] for k in sorted(x)];
}