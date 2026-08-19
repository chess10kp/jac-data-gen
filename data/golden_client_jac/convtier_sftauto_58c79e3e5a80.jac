def filter_words(string: Any) -> object {
    words = string.split();
    filtered_words = [];
    for word in words {
        if ((len(word) > 5) and (len(`set(word)) == len(word))) {
            filtered_words.append(word);
        }
    }
    return filtered_words;
}



with entry {
    print(filter_words('hello'));
    print(filter_words('Hello, World!'));
}
