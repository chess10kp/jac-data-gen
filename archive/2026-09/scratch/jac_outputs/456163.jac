def maximumProduct(nums: list[int]) -> int {
    nums = sorted(nums);
    first_option = nums[0] * nums[1] * nums[-1];
    second_option = nums[-3] * nums[-2] * nums[-1];
    return first_option if first_option > second_option else second_option;
}