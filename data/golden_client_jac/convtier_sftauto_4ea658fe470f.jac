def generate_frequency_table(sequence: Any) -> object {
    frequency_table = {};
    for char in sequence {
        if (char in frequency_table) {
            frequency_table[char] += 1;
        } else {
            frequency_table[char] = 1;
        }
    }
    return frequency_table;
}



with entry {
    print(generate_frequency_table('hello'));
    print(generate_frequency_table('Racecar'));
    print(generate_frequency_table('abcabc'));
}
