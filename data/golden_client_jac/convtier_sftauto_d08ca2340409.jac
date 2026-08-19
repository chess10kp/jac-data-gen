def find_anagrams(word: Any) -> object {
    word = word.lower();
    sorted_word = sorted(word);
    anagrams = [];
    for i in range(1, (len(word) + 1)) {
        for j in range(((len(word) - i) + 1)) {
            substring = word[j:(j + i)];
            sorted_substring = sorted(substring);
            if ((sorted_substring == sorted_word) and (len(substring) <= len(word))) {
                anagrams.append(substring);
            }
        }
    }
    return sorted(anagrams);
}



with entry {
    print(find_anagrams('hello'));
    print(find_anagrams('Racecar'));
    print(find_anagrams('abcabc'));
}
