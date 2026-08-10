"""Gets errno from exception or returns one."""
def get_error(exception: object | None = None) -> int {
    return getattr(exception, "errno", 1);
}