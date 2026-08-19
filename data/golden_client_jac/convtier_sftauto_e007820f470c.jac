def remove_duplicates(nums: Any) -> object {
    distinct_nums = `list(`set(nums));
    sorted_nums = sorted(distinct_nums, reverse=True);
    return sorted_nums;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
