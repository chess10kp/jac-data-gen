def frequency_table(nums: Any) -> object {
    freq = {};
    duplicate_index = {};
    for num in nums {
        if (num in freq) {
            index = duplicate_index.get(num, 0) + 1;
            freq[f"{num}{chr((ord('a') + index))}"] = 1;
            duplicate_index[num] = index;
        } else {
            freq[num] = 1;
        }
    }
    return freq;
}



with entry {
    print(frequency_table('hello'));
    print(frequency_table('Racecar'));
    print(frequency_table('abcabc'));
}
