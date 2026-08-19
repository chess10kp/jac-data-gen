def removeDuplicates(nums: Any) -> object {
    unique_set = `set();
    result = [];
    for num in nums {
        if (num not in unique_set) {
            unique_set.add(num);
            result.append(num);
        }
    }
    return result;
}



with entry {
    print(removeDuplicates('hello'));
    print(removeDuplicates('Racecar'));
    print(removeDuplicates('abcabc'));
}
