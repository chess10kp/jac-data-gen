def frequency_table(lst: Any) -> object {
    freq_table = {};
    for num in lst {
        if (num in freq_table) {
            freq_table[num] += 1;
        } else {
            freq_table[num] = 1;
        }
    }
    return freq_table;
}



with entry {
    print(frequency_table('hello'));
    print(frequency_table('Racecar'));
    print(frequency_table('abcabc'));
}
