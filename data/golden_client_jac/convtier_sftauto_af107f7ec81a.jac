def count_frequencies(sentence: Any) -> object {
    frequencies = {};
    for char in sentence {
        if (char.isalpha() or (char in string.punctuation)) {
            char = char.lower();
            if (char in frequencies) {
                frequencies[char] += 1;
            } else {
                frequencies[char] = 1;
            }
        }
    }
    return frequencies;
}



with entry {
    print(count_frequencies('hello'));
    print(count_frequencies('Racecar'));
    print(count_frequencies('abcabc'));
}
