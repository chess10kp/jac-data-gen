"""Returns the max subarray of the given list of numbers.
    Returns 0 if nums is None or an empty list.
    Time Complexity: O(n)
    Space Complexity: O(n)
"""
def max_sub_array(nums: list[int] | None) -> int {
    if nums is None { return 0; }
    if len(nums) == 0 { return 0; }
    max_sum = 0;
    current_sum = 0;
    for num in nums {
        current_sum = max(num + current_sum, num);
        max_sum = max(current_sum, max_sum);
    }
    if max_sum <= 0 { return max(nums); }
    return max_sum;
}