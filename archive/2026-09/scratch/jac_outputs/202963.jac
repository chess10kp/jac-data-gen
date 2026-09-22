"""Add two numbers together. Raises ValueError if lhs is zero."""
def my_function(lhs: int, rhs: int) -> int {
    if lhs == 0 { raise ValueError(); }
    return lhs + rhs;
}