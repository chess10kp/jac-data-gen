def remove_duplicates(nums: Any) -> object {
    unique_nums = [];
    seen_nums = `set();
    for num in nums {
        if (num not in seen_nums) {
            unique_nums.append(num);
            seen_nums.add(num);
        }
    }
    return unique_nums;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
