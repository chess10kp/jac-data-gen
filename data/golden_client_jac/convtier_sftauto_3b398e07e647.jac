def filter_words(string: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    words = string.split(', ');
    result = [];
    for word in words {
        if ((word[0].lower() in vowels) and ((len(word) % 2) != 0)) {
            result.append(word);
        }
    }
    return result;
}



with entry {
    print(filter_words('hello'));
}
