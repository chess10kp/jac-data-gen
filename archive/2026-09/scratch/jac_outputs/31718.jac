"""Calculate the value of the given path."""
def calculations(pyramid: list[list[int]], i: list[int]) -> int {
    res = 1;
    for (x, row) in enumerate(pyramid) {
        res *= row[i[x]];
    }
    return res;
}