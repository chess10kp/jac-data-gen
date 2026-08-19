def find_max_indices(nums: Any) -> object {
    if not nums {
        return [];
    }
    max_num = max(nums);
    indices = [
        i
        for (i, num) in enumerate(nums)
        if (num == max_num)
    ];
    return indices;
}



with entry {
    print(find_max_indices('hello'));
    print(find_max_indices('Racecar'));
    print(find_max_indices('abcabc'));
}
