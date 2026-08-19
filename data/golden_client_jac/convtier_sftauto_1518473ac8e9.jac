def remove_duplicates(nums: Any) -> object {
    unique_nums = `set();
    result = [];
    for num in nums {
        if (num not in unique_nums) {
            unique_nums.add(num);
            result.append(num);
        }
    }
    return result;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
