def count_hello(words: Any) -> object {
    count = 0;
    for word in words {
        if (word == "hello") {
            count += 1;
        }
    }
    return count;
}



with entry {
    print(count_hello('hello'));
}
