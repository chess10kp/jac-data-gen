"""Threshold a value to a minimum int."""
def threshold(number: int, minNumber: int = 20) -> int {
    return number if abs(number) >= minNumber else 0;
}