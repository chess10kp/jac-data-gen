def count_unique_vowels(sentence: Any) -> object {
    vowels = `set(['a', 'e', 'i', 'o', 'u']);
    consonants = `set(
        [
            'b',
            'c',
            'd',
            'f',
            'g',
            'h',
            'j',
            'k',
            'l',
            'm',
            'n',
            'p',
            'q',
            'r',
            's',
            't',
            'v',
            'w',
            'x',
            'y',
            'z'
        ]
    );
    unique_vowels = `set();
    prev_char = '';
    for char in sentence {
        if ((char.lower() in vowels) and (prev_char.lower() in consonants)) {
            unique_vowels.add(char.lower());
        }
        prev_char = char;
    }
    return len(unique_vowels);
}



with entry {
    print(count_unique_vowels('hello'));
    print(count_unique_vowels('abcabc'));
}
