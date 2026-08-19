def find_longest_even_words(words: List[str]) -> List[str] {
    max_length = 0;
    result = [];
    for word in words {
        if ((len(word) % 2) == 0) {
            if (len(word) > max_length) {
                max_length = len(word);
                result = [word];
            } elif (len(word) == max_length) {
                result.append(word);
            }
        }
    }
    return result;
}



with entry {
    print(find_longest_even_words('hello'));
}
