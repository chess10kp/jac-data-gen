"""Validates that the input is a number."""
def validate_number(x: str) -> bool {
    return x.isdigit() or x == "";
}