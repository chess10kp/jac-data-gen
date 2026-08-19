def second_largest(nums: list[int]) -> int {
    distinct = sorted(set(nums));
    return distinct[-2];
}

with entry {
    print(second_largest([3, 1, 4, 1, 5]));
}
