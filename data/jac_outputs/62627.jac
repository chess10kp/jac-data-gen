"""Split a line read from file into a name/sequence tuple."""
def split_line(line: str) -> tuple[str, str] {
    stripped = line.strip('\n');
    return (stripped.split('\t')[0], stripped.split('\t')[-1]);
}