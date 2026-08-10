"""Return value modulo the max of the valid range."""
def modular_range(value: int, values: set[int]) -> int {
    return value % max(values);
}