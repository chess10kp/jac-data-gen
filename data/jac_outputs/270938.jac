"""If total=100 and n=50 => 50%."""
def percentage(n: int | float | None, total: int | float) -> float | int {
    if n is None {
        return 0;
    }
    return (n * 100) / total;
}