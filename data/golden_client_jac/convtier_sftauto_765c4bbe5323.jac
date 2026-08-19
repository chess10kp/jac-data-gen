def sort_words(words: Any) -> object {
    unique_words = `list(`set(words));
    unique_words = [word.lower() for word in unique_words];
    unique_words.sort(reverse=True);
    return unique_words;
}



with entry {
    print(sort_words('hello'));
    print(sort_words('Racecar'));
    print(sort_words('abcabc'));
}
