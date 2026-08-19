def bubble_sort_descending(words: Any) -> object {
    n = len(words);
    for i in range((n - 1)) {
        for j in range((n - 1 - i)) {
            if (len(words[j]) < len(words[(j + 1)])) {
                (words[j], words[(j + 1)]) = (words[(j + 1)], words[j]);
            }
        }
    }
    return words;
}



with entry {
    print(bubble_sort_descending('hello'));
    print(bubble_sort_descending('Racecar'));
    print(bubble_sort_descending('abcabc'));
}
