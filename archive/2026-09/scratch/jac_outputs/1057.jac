"""Compares two values and returns MongoDB $gt aggregation operator."""
def GT(x: int | float | str | dict[str, str | int | float] | None = None, y: int | float | str | dict[str, str | int | float] | None = None) -> dict[str, list[int | float | str | dict[str, str | int | float] | None]] {
    if x is None and y is None {
        return {'$gt': []};
    }
    return {'$gt': [x, y]};
}