"""Apply a function across each line in a flat string."""
def MapLines(f: Callable[[str], str], s: str) -> str {
    return '\n'.join(f(line) for line in s.split('\n'));
}