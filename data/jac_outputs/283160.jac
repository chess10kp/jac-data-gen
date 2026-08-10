"""Call a variable if it's a callable, otherwise return it."""
def _call_if_callable[T](s: T | callable[[], T]) -> T {
    if hasattr(s, '__call__') {
        return s();
    }
    return s;
}