def find_duplicates(nums: Any) -> object {
    seen = {};
    duplicates = [];
    for (i, num) in enumerate(nums) {
        if (num in seen) {
            duplicates.append((num, seen[num]));
        }
        seen[num] = i;
    }
    return duplicates;
}



with entry {
    print(find_duplicates('hello'));
    print(find_duplicates('Racecar'));
    print(find_duplicates('abcabc'));
}
