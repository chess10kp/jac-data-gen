"""
    Find the value of an integer at a specific digit when represented in a
    particular base.
    """
def digit(decimal: int, digit: int, input_base: int = 10) -> int {
    if decimal == 0 {
        return 0;
    }
    if digit != 0 {
        return (decimal // (input_base ** digit)) % input_base;
    } else {
        return decimal % input_base;
    }
}