def count_distinct_numbers(nums: Any) -> object {
    distinct_nums = {};
    count = 0;
    for num in nums {
        if (num not in distinct_nums) {
            distinct_nums[num] = True;
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_distinct_numbers('hello'));
    print(count_distinct_numbers('Racecar'));
    print(count_distinct_numbers('abcabc'));
}
