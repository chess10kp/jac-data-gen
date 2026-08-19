def sort_negative_numbers(lst: Any) -> object {
    negative_nums = [
        num
        for num in lst
        if (num < 0)
    ];
    n = len(negative_nums);
    for i in range((n - 1)) {
        for j in range((n - i - 1)) {
            if (negative_nums[j] > negative_nums[(j + 1)]) {
                (negative_nums[j], negative_nums[(j + 1)]) = (
                    negative_nums[(j + 1)],
                    negative_nums[j]
                );
            }
        }
    }
    return negative_nums;
}



with entry {
    print(sort_negative_numbers([]));
}
