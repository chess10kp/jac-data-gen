"""Return the last argument. Helpful in making lambdas do more than one thing."""
def argn(*args: int | float | str | bool) -> int | float | str | bool {
    return args[-1];
}