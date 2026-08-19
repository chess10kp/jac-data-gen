def reverse_in_place(string: Any) -> object {
    chars = `list(string);
    length = len(chars);
    for i in range((length // 2)) {
        (chars[i], chars[(length - i - 1)]) = (chars[(length - i - 1)], chars[i]);
    }
    return ''.join(chars);
}



with entry {
    print(reverse_in_place('hello'));
    print(reverse_in_place('Racecar'));
    print(reverse_in_place('abcabc'));
}
