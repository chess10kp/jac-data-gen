def count_unique_characters(string: Any) -> object {
    string = string.replace(" ", "");
    string = string.lower();
    counts = {};
    for char in string {
        if char.isalpha() {
            if (char in counts) {
                counts[char] += 1;
            } else {
                counts[char] = 1;
            }
        }
    }
    return counts;
}



with entry {
    print(count_unique_characters('hello'));
    print(count_unique_characters('Racecar'));
    print(count_unique_characters('abcabc'));
}
