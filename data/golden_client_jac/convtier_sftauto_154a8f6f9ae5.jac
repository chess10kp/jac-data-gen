def get_positive_numbers(nums: Any) -> object {
    positive_nums = [];
    for num in nums {
        if (num > 0) {
            positive_nums.append(num);
        }
    }
    return positive_nums;
}



with entry {
    print(get_positive_numbers([]));
}
