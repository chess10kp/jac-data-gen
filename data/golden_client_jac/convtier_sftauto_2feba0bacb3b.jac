def count_vowels(word: Any) -> object {
    vowels = 'aeiou';
    distinct_vowels = `set(
        ch
        for ch in word
        if (ch.lower() in vowels)
    );
    return len(distinct_vowels);
}



with entry {
    print(count_vowels('hello'));
    print(count_vowels('abcabc'));
    print(count_vowels([]));
}
