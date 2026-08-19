def reverse_array(nums: Any) -> object {
    reversed_nums = [];
    for i in range((len(nums) - 1), -1, -1) {
        reversed_nums.append(nums[i]);
    }
    return reversed_nums;
}



with entry {
    print(reverse_array('hello'));
    print(reverse_array('Racecar'));
    print(reverse_array('abcabc'));
}
