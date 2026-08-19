def is_arithmetic(nums: List[int]) -> bool {
    if (len(nums) <= 1) {
        return True;
    }
    diff = nums[1] - nums[0];
    for i in range(1, (len(nums) - 1)) {
        if ((nums[(i + 1)] - nums[i]) != diff) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_arithmetic([]));
}
