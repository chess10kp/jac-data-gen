def count_substrings(sentence: Any) -> object {
    counter = 0;
    vowels = ['a', 'e', 'i', 'o', 'u'];
    consonants = [
        chr(x)
        for x in range(ord('a'), (ord('z') + 1))
        if (chr(x) not in vowels)
    ];
    for i in range((len(sentence) - 3)) {
        if (sentence[i] in vowels) {
            if ((sentence[(i + 1)] != '') and (sentence[(i + 2)] != '')) {
                if (sentence[(i + 3)] in consonants) {
                    counter += 1;
                }
            }
        }
    }
    return counter;
}



with entry {
    print(count_substrings('hello'));
    print(count_substrings('Racecar'));
    print(count_substrings('level'));
}
