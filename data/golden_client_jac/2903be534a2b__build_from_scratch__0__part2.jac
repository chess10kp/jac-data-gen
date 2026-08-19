def filter_positive(nums: list) -> list {
    return [n for n in nums if n > 0];
}

with entry {
    for x in [[-1, 2, -3, 4], [0, 1, 2], [-5, -6], [3, 0, -1, 9]] {
        print(filter_positive(x));
    }
}
