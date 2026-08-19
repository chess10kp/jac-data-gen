def longest_vowel_string(strings: Any) -> object {
    vowels = {'a', 'e', 'i', 'o', 'u'};
    longest_string = "";
    for string in strings {
        if ((len(string) > 3) and (string[0] in vowels)) {
            for i in range((len(string) - 1)) {
                if (string[i] == string[(i + 1)]) {
                    if (len(string) > len(longest_string)) {
                        longest_string = string;
                    }
                    break;
                }
            }
        }
    }
    return longest_string;
}



with entry {
    print(longest_vowel_string('hello'));
}
