def find_median(nums: Any) -> object {
    nums.sort();
    n = len(nums);
    if ((n % 2) == 0) {
        median = (nums[((n // 2) - 1)] + nums[(n // 2)]) / 2;
    } else {
        median = nums[(n // 2)];
    }
    return median;
}



with entry {
    print(find_median([81]));
    print(find_median(['a']));
    print(find_median([100]));
}
