"""Find the range of a set of data (difference between max and min)."""
def dataRange(data: list[int]) -> int {
    data.sort();
    return data[len(data) - 1] - data[0];
}