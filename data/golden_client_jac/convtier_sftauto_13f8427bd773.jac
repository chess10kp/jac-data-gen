def count_distinct_vowels(string: Any) -> object {
    vowels = `set(['a', 'e', 'i', 'o', 'u']);
    distinct_vowels = `set();
    string = string.lower();
    prev_char = None;
    for char in string {
        if (char in vowels) {
            if (char != prev_char) {
                distinct_vowels.add(char);
            }
        }
        prev_char = char;
    }
    return len(distinct_vowels);
}



with entry {
    print(count_distinct_vowels('hello'));
    print(count_distinct_vowels('abcabc'));
}
