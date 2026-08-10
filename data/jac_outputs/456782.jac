"""Based on project: https://github.com/chaeplin/dashmnb."""
def from_string_to_bytes(a: str | bytes) -> bytes {
    return a if isinstance(a, bytes) else bytes(a, 'utf-8');
}