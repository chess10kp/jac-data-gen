"""Return res as a string, unless res is None, in which case it returns the empty string."""
def str_or_null(res: int | float | str | bool | None) -> str {
    if res is None {
        return '';
    }
    return str(res);
}