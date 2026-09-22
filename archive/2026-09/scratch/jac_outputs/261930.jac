"""
    If the default is a callable, return result of its execution. Return raw value otherwise.
    """
def _return_default(`default: Any) -> object {
    return `default() if callable(`default) else `default;
}