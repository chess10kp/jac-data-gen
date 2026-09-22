"""n takes priority."""
def get_number_and_percentage(total: int, n: int | None, percentage: float) -> tuple[int, float] {
    if n == -1 {
        return (total, 1.0);
    } elif n is not None and n > 0 {
        if n >= total {
            return (total, 1.0);
        }
        return (n, float(n) / total);
    }
    assert isinstance(percentage, float);
    return (int(total * percentage), percentage);
}