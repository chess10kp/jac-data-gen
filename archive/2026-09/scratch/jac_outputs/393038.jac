"""Compose the specified 8-bit *values* into a single integer."""
def compose(*values: int) -> int {
    result = 0;
    for (i, value) in enumerate(values) {
        result |= value << (i * 8);
    }
    return result;
}