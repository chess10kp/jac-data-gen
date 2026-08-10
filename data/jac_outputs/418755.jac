"""Calculates the mean of a list of numbers."""
def mean(*args: int | float) -> float | str {
    index = 0;
    sum_index = 0.0;
    for i in args {
        index += 1;
        sum_index += float(i);
    }
    return sum_index / index if index != 0 else "Division by zero";
}