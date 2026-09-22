"""Pass in string for forward, string for reverse."""
def parse_str(arg: str, reverse: bool = False) -> str {
    return '%s' % arg if reverse else str(arg);
}