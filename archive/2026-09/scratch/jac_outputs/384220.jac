"""Read values from a string."""
def read_values(xs: str, sep: str, *values: str) -> dict[str, int] {
    parts = [x.strip() for x in xs.split(sep)];
    if len(parts) != len(values) {
        raise ValueError(f"Expected {len(values)} values, but got {len(parts)}.");
    }
    return {v: int(x) for (v, x) in zip(values, parts)};
}