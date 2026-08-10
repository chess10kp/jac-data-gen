"""convert to integers"""
def _to_int(x: list[str | int | float]) -> tuple[int, int] {
    return (int(x[0]), int(x[1]));
}