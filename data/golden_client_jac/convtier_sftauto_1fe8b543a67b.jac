def reverse_string(string: Any) -> object {
    return string[::-1];
}



with entry {
    print(reverse_string('hello'));
    print(reverse_string('Racecar'));
    print(reverse_string('abcabc'));
}
