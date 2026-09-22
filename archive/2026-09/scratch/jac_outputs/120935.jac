"""Find the minimum value in an iterable; return None if empty."""
def minimum(numbers: list[int | float]) -> int | float | None {
    if not numbers {
        return None;
    }
    min_number = numbers[0];
    for number in numbers {
        min_number = number if number < min_number else min_number;
    }
    return min_number;
}