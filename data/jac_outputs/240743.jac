"""Multiply the first two positional arguments."""
def multiply_with_positional_args(*args: int | float) -> int | float {
    args[0] * args[1]
}