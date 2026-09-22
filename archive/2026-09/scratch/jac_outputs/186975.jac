"""Checks if it is an unbounded method."""
def is_unbound(method: Any) -> object {
    return not (hasattr(method, '__self__') and method.__self__);
}