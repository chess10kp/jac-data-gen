def maxSubarraySum(arr: Any) -> object {
    maxSum = float('-inf');
    currSum = 0;
    for num in arr {
        currSum = max(num, (currSum + num));
        maxSum = max(maxSum, currSum);
    }
    return maxSum;
}



with entry {
    print(maxSubarraySum([]));
    print(maxSubarraySum([-10368, 1296]));
    print(maxSubarraySum([-10368, -126, 882]));
}
