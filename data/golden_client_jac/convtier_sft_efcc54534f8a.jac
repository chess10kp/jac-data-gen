def pairwise_diffs(nums: list[int]) -> list[int] {
    return [b - a for (a, b) in zip(nums, nums[1:])];
}

with entry {
    print(pairwise_diffs([1, 4, 9, 16]));
}
