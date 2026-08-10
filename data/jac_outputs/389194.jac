"""Returns all numbers which are divisible by the given divisor."""
def divisible_by(numbers: list[int] | None, divisor: int) -> list[int] {
    if numbers is None {
        return [];
    }
    return [item for item in numbers if item % divisor == 0];
}