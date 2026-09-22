"""Calculates the sum (or difference) of two numbers."""
def calculate(x: int, y: int = 1, *, subtract: bool = False) -> int {
    return x - y if subtract else x + y;
}