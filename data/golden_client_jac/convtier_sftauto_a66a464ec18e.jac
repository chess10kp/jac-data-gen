def reverse_string(string: Any) -> object {
    string = `list(string);
    start = 0;
    end = len(string) - 1;
    while (start < end) {
        (string[start], string[end]) = (string[end], string[start]);
        start += 1;
        end -= 1;
    }
    return ''.join(string);
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
