"""
Call a function for its side effect after initialization.
"""
def call_aside(
    f: Callable, *args: int | float | str | bool, **kwargs: str | int | float | bool
) -> Callable {
    f(*args, **kwargs);
    return f;
}