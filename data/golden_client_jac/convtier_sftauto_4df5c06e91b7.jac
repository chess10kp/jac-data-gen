def removeDuplicatesAndSort(nums: Any) -> object {
    distinct_nums = `set();
    for num in nums {
        distinct_nums.add(num);
    }
    return sorted(`list(distinct_nums));
}



with entry {
    print(removeDuplicatesAndSort('hello'));
    print(removeDuplicatesAndSort('Racecar'));
    print(removeDuplicatesAndSort('abcabc'));
}
