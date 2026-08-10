"""Returns the max subarray of the given list of numbers.
        Returns 0 if  nums is None or an empty list.
        Time Complexity: O(n)
        Space Complexity: O(1)
    """
def max_sub_array(nums: list[int] | None) -> int {
    if nums == None {
        return 0;
    }
    numbers = nums as list[int];
    if len(numbers) == 0 {
        return 0;
    }
    dp = [0 for i in range(len(numbers))];
    dp[0] = numbers[0];
    for i in range(1, len(numbers)) {
        dp[i] = max(dp[i - 1] + numbers[i], numbers[i]);
    }
    return max(dp);
}