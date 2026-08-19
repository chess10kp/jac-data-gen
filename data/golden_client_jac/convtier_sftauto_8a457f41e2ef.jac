def find_maximum(nums: Any) -> object {
    diff1 = `abs((nums[0] - nums[1]));
    diff2 = `abs((nums[0] - nums[2]));
    diff3 = `abs((nums[1] - nums[2]));
    max_num = (diff1 + diff2 + diff3) / 2;
    max_num -= `abs(diff1);
    max_num -= `abs(diff2);
    max_num -= `abs(diff3);
    max_num /= 2;
    return max_num;
}



with entry {
    print(find_maximum([-8, -4, 2, 6]));
    print(find_maximum([4, 7, -1, 9, -2]));
}
