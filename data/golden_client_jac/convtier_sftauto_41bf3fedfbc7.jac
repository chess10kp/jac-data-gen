def sort_string(string: Any) -> object {
    chars = `list(string);
    for i in range(len(chars)) {
        for j in range((len(chars) - 1 - i)) {
            if (chars[j] > chars[(j + 1)]) {
                (chars[j], chars[(j + 1)]) = (chars[(j + 1)], chars[j]);
            }
        }
    }
    sorted_string = ''.join(chars);
    return sorted_string;
}



with entry {
    print(sort_string('hello'));
    print(sort_string('Racecar'));
    print(sort_string('abcabc'));
}
