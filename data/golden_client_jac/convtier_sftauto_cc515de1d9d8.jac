def count_vowels(text: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    vowel_counts = {vowel: 0 for vowel in vowels};
    for char in text {
        if (char.lower() in vowels) {
            vowel_counts[char.lower()] += 1;
        }
    }
    return vowel_counts;
}



with entry {
    print(count_vowels('hello'));
    print(count_vowels('Racecar'));
    print(count_vowels('abcabc'));
}
