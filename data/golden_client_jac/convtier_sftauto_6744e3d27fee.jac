def find_duplicate(nums: Any) -> object {
    nums.sort();
    for i in range((len(nums) - 1)) {
        if (nums[i] == nums[(i + 1)]) {
            return nums[i];
        }
    }
    return -1;
}



with entry {
    print(find_duplicate([]));
}
