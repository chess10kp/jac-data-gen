"""Returns the max subarray of the given list of numbers.

Returns 0 if nums is None or an empty list."""
def max_sub_array(
    nums: list[int] | None,
    max_sum: int | None = None,
    current_sum: int = 0,
    current_index: int = 0
) -> int {
    if nums == None {
        return 0;
    }
    if len(nums) == 0 {
        return 0;
    }
    if not max_sum {
        max_sum = nums[0];
    }
    if current_index == len(nums) {
        if current_sum < max_sum and nums[current_index - 1] > max_sum {
            max_sum = nums[current_index - 1];
        }
        return max_sum;
    }
    current_sum += nums[current_index];
    if current_sum >= max_sum {
        return max_sub_array(
            nums,
            max_sum=current_sum,
            current_sum=current_sum,
            current_index=current_index + 1
        );
    }
    return max_sub_array(
        nums, max_sum, current_sum, current_index=current_index + 1
    );
}