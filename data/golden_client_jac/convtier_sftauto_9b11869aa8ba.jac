def calculate_sum(nums: Any) -> object {
    def calculate_sum_helper(nums: Any, curr_sum: Any) -> object {
        if (not nums or (nums[0] < 0)) {
            return curr_sum;
        }
        return calculate_sum_helper(nums[1:], (curr_sum + nums[0]));
    }
    return calculate_sum_helper(nums, 0);
}



with entry {
    print(calculate_sum(0));
}
