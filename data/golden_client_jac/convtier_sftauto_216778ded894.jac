def reverse_array(nums: Any) -> object {
    reversed_nums = nums[::-1];
    reversed_nums.sort(reverse=True);
    return reversed_nums;
}



with entry {
    print(reverse_array([1, 2, 4]));
    print(reverse_array([1, 2]));
    print(reverse_array([5, 5, 5]));
}
