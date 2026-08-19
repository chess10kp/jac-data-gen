def calculate_median(nums: Any) -> object {
    nums.sort();
    n = len(nums);
    if ((n % 2) == 0) {
        mid1 = n // 2;
        mid2 = mid1 - 1;
        return ((nums[mid1] + nums[mid2]) / 2);
    } else {
        mid = n // 2;
        return nums[mid];
    }
}



with entry {
    print(calculate_median([-9]));
    print(calculate_median([10, 20]));
    print(calculate_median([-8, -4, 2, 6]));
}
