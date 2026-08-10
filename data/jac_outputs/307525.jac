"""returns mean of a list of values"""
def mean(values: list[int | float]) -> float {
    if not values {
        return 0;
    }
    return float(sum(values)) / len(values);
}