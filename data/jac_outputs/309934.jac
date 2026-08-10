"""Remove single spaces from column names in a header line."""
def despace(line: str) -> str {
    return ''.join([p if p else ' ' for p in line.split(' ')]);
}