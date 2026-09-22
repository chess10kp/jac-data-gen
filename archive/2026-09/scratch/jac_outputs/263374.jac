"""Draw a sample of n lines from filename, largely evenly."""
def sample_lines(lines: list[str], n: int) -> str {
    if len(lines) <= n {
        return "".join(lines);
    }
    m = len(lines);
    return "".join([lines[(x * m) // n + m // (2 * n)] for x in range(n)]);
}