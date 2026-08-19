def sort_list(nums: Any) -> object {
    nums = `list(`set(nums));
    n = len(nums);
    for i in range(n) {
        for j in range(0, (n - i - 1)) {
            if (nums[j] > nums[(j + 1)]) {
                (nums[j], nums[(j + 1)]) = (nums[(j + 1)], nums[j]);
            }
        }
    }
    return nums;
}



with entry {
    print(sort_list('hello'));
    print(sort_list('Racecar'));
    print(sort_list('abcabc'));
}
