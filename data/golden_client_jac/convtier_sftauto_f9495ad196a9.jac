def reverse_strings(strings: Any) -> object {
    return [s[::-1] for s in strings];
}



with entry {
    print(reverse_strings('hello'));
    print(reverse_strings('Racecar'));
    print(reverse_strings('abcabc'));
}
