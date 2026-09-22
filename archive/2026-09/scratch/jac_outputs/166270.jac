"""
    Constructs full module path for a given function.

    Args:
        f (function): Function to construct the path for

    Returns:
        str
    """
def get_full_function_name(f: Callable[..., object]) -> str {
    return f"{f.__module__}.{f.__qualname__}";
}