"""Return the index and direct links described by a pipe string."""
def parse_line(line: str) -> tuple[str, list[str]] {
    (k, v) = line.strip().split(' <-> ');
    return (k, v.split(', '));
}