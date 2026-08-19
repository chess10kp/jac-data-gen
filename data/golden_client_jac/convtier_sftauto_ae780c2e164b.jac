def find_3_highest_distinct_numbers(nums: Any) -> object {
    count = {};
    for num in nums {
        count[num] = count.get(num, 0) + 1;
    }
    distinct_nums = `list(count.keys());
    distinct_nums.sort(reverse=True);
    return distinct_nums[:3];
}



with entry {
    print(find_3_highest_distinct_numbers('hello'));
    print(find_3_highest_distinct_numbers('Racecar'));
    print(find_3_highest_distinct_numbers('abcabc'));
}
