def bubble_sort(nums: Any) -> object {
    n = len(nums);
    for i in range((n - 1)) {
        for j in range(0, (n - i - 1)) {
            if (nums[j] > nums[(j + 1)]) {
                (nums[j], nums[(j + 1)]) = (nums[(j + 1)], nums[j]);
            }
        }
    }
    return nums;
}



with entry {
    print(bubble_sort([]));
}
