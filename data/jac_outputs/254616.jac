"""Compute the TLE checksum for the given line."""
def compute_checksum(line: Any) -> object {
    return (sum(int(c) if c.isdigit() else (c == '-') for c in line[0:68]) % 10);
}