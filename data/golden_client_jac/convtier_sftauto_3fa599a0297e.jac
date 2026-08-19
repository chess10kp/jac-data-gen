def remove_reverse_string(s: Any) -> object {
    index = s.find('o');
    s = s[:index] + s[(index + 1):];
    s = s[::-1];
    s = s.lower();
    return s;
}



with entry {
    print(remove_reverse_string('hello'));
    print(remove_reverse_string('Racecar'));
    print(remove_reverse_string('abcabc'));
}
