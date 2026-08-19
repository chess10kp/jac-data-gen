def max_difference(nums: Any) -> object {
    max_diff = 0;
    min_num = nums[0];
    for num in nums {
        if (num < min_num) {
            min_num = num;
        }
        diff = num - min_num;
        if (diff > max_diff) {
            max_diff = diff;
        }
    }
    return max_diff;
}



with entry {
    print(max_difference([0]));
    print(max_difference([7, -1, -4, -2]));
}
