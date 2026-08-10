"""Detect nulls in other types."""
def is_void(data: str | int | list[str]) -> str {
    if data in ('', 0, []) {
        return 'is empty';
    }
    return 'have data';
}