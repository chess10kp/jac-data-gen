"""Supplies the module name and functon name as a 2-tuple."""
def _parse_id(func: Callable) -> tuple[str, str] {
    return (func.__module__.split(".")[-1], func.__name__);
}