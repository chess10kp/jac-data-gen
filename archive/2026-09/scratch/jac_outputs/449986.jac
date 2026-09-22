"""Join version tuple to string."""
def version_tuple_to_str(version: tuple[int, ...]) -> str {
    return '.'.join(map(str, version));
}