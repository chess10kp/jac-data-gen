def find_median(nums: Any) -> object {
    nums.sort();
    length = len(nums);
    if ((length % 2) == 1) {
        return nums[(length // 2)];
    } else {
        middle1 = nums[((length // 2) - 1)];
        middle2 = nums[(length // 2)];
        return ((middle1 + middle2) / 2);
    }
}



with entry {
    print(find_median([-10368, 1296]));
    print(find_median([-10368, -1296, -126, 882]));
}
