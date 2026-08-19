def reverse_and_modify(input_str: Any) -> object {
    words = input_str.split();
    length = len(words);
    start_index = (length // 2) + (length % 2);
    reversed_words = [];
    for word in words[start_index:] {
        if (word[0].lower() in ['a', 'e', 'i', 'o', 'u']) {
            reversed_words.append(
                word.replace('a', '').replace('e', '').replace('i', '').replace(
                    'o', ''
                ).replace(
                    'u', ''
                )
            );
        } else {
            reversed_words.append(word[::-1]);
        }
    }
    return ', '.join(reversed_words);
}



with entry {
    print(reverse_and_modify('hello'));
    print(reverse_and_modify('Hello, World!'));
    print(reverse_and_modify('step on no pets'));
}
