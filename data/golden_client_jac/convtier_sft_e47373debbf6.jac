def is_sorted(nums: list[int]) -> bool {
    for i in range(len(nums) - 1) {
        if nums[i] > nums[i + 1] { return False; }
    }
    return True;
}

with entry {
    print(is_sorted([1, 2, 3]));
    print(is_sorted([3, 1, 2]));
}
