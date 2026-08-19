def max_list(nums: list[int]) -> int {
    best = nums[0];
    for n in nums {
        if n > best { best = n; }
    }
    return best;
}

with entry {
    print(max_list([3, 7, 2, 9, 4]));
}
