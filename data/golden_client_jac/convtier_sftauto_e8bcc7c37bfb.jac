def max_subarray_sum(arr: Any) -> object {
    if (len(arr) < 2) {
        return 0;
    }
    dp = [0] * len(arr);
    dp[0] = max(0, arr[0]);
    dp[1] = max(dp[0], arr[1]);
    for i in range(2, len(arr)) {
        dp[i] = max(dp[(i - 1)], (dp[(i - 2)] + arr[i]));
    }
    return dp[-1];
}



with entry {
    print(max_subarray_sum([]));
}
