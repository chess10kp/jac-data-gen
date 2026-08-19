def count_repeated_words(sentence: Any) -> object {
    words = sentence.split();
    count = {};
    for word in words {
        if ('e' not in word) {
            if (word not in count) {
                count[word] = 1;
            } else {
                count[word] += 1;
            }
        }
    }
    return count;
}



with entry {
    print(count_repeated_words('hello'));
    print(count_repeated_words('abcabc'));
    print(count_repeated_words('Hello, World!'));
}
