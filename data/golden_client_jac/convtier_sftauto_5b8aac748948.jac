def reverse_string(s: Any) -> object {
    chars = `list(s);
    n = len(s);
    for i in range((n // 2)) {
        (chars[i], chars[(n - i - 1)]) = (chars[(n - i - 1)], chars[i]);
    }
    return ''.join(chars);
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
