def longest_increasing_subsequence(nums: Any) -> object {
    n = len(nums);
    dp = [1] * n;
    for i in range(1, n) {
        for j in range(i) {
            if (nums[i] > nums[j]) {
                dp[i] = max(dp[i], (dp[j] + 1));
            }
        }
    }
    return max(dp);
}



with entry {
    print(longest_increasing_subsequence('hello'));
    print(longest_increasing_subsequence('Racecar'));
    print(longest_increasing_subsequence('level'));
}
