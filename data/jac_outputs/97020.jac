"""returns string to camel caps."""
def to_camel(s: str) -> str {
    return str(s.title().replace('_', ''));
}