def filter_words(words: Any) -> object {
    filtered_words = [];
    for word in words {
        if ((len(word) >= 7) and (('a' in word.lower()) or ('e' in word.lower()))) {
            filtered_words.append(word.lower());
        }
    }
    filtered_words = `list(`set(filtered_words));
    filtered_words.sort(reverse=True);
    return filtered_words[:5000];
}



with entry {
    print(filter_words('hello'));
}
