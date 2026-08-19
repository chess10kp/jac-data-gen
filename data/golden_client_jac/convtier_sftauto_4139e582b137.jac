def count_distinct_words(string: Any) -> object {
    distinct_words = `set();
    words = string.split();
    for word in words {
        distinct_words.add(word.lower());
    }
    return len(distinct_words);
}



with entry {
    print(count_distinct_words('hello'));
    print(count_distinct_words('Hello, World!'));
    print(count_distinct_words('step on no pets'));
}
