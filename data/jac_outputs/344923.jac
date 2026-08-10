"""Convert absolute and total values to percent."""
def percent(value: int | float, total: int | float) -> float {
    if total {
        return float(value) * 100.0 / float(total);
    } else {
        return 100.0;
    }
}