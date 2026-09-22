"""Divide dividend by divisor."""
def divide(dividend: str, divisor: str) -> int | str {
    try {
        return int(dividend) // int(divisor);
    } except (ZeroDivisionError, ValueError) as exception {
        return f"{exception.__class__.__name__}: {exception}";
    }
}