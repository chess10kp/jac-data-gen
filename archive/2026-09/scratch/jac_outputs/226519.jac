"""Returns how many numbers between `maximum` and `minimum` in a given `row`"""
def examp01(row: list[int], minimum: int, maximum: int) -> int {
    count = 0;
    for n in row {
        if minimum <= n <= maximum {
            count += 1;
        }
    }
    return count;
}