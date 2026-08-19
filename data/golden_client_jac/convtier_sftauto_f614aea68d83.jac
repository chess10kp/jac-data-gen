def find_distinct_values(nums: Any) -> object {
    distinct_values = `set();
    for num in nums {
        distinct_values.add(num);
    }
    return sorted(`list(distinct_values));
}



with entry {
    print(find_distinct_values('hello'));
    print(find_distinct_values('Racecar'));
    print(find_distinct_values('abcabc'));
}
