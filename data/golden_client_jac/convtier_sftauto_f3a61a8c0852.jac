def find_median(nums: Any) -> object {
    if (len(nums) == 0) {
        return None;
    }
    nums.sort();
    if ((len(nums) % 2) == 0) {
        middle_index = len(nums) // 2;
        return ((nums[(middle_index - 1)] + nums[middle_index]) / 2);
    } else {
        middle_index = len(nums) // 2;
        return nums[middle_index];
    }
}



with entry {
    print(find_median([-9, 2]));
    print(find_median([2]));
    print(find_median([34]));
}
