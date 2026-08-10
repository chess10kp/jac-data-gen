obj HasIsNumber {
    has is_number: bool;
}

"""Checks whether expression is a number."""
def check_is_number(expression: int | float | HasIsNumber) -> bool {
    return isinstance(expression, (int, float)) or expression.is_number;
}