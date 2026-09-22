"""Return the upper bound of a divide operation."""
def div_up(a: Any, b: Any) -> object {
    return (((a + b) - 1) // b);
}