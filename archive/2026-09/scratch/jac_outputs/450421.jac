"""Ensure we can serialize a celery result."""
def _flatten_result(result: Exception | str | int | float | bool | list[str] | dict[str, str]) -> str | int | float | bool | list[str] | dict[str, str] {
    if issubclass(`type(result), Exception) {
        return getattr(result, 'message') as str;
    }
    return result as str | int | float | bool | list[str] | dict[str, str];
}