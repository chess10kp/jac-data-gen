"""Split each line into columns."""
def split_data(line: str) -> list[str] {
    data = line.split(',');
    return [data[0], data[1]];
}