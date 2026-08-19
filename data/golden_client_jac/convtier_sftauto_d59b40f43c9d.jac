def find_median(nums: Any) -> object {
    nums.sort();
    n = len(nums);
    if ((n % 2) == 0) {
        mid1 = nums[(n // 2)];
        mid2 = nums[((n // 2) - 1)];
        median = (mid1 + mid2) / 2;
    } else {
        median = nums[(n // 2)];
    }
    return median;
}



with entry {
    print(find_median([2, 9]));
    print(find_median([2]));
    print(find_median([34]));
}
