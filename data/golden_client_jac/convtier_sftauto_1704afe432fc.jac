def get_sorted_string(string: Any) -> object {
    string = ''.join(
        ch.lower()
        for ch in string
        if ch.isalpha()
    );
    return ''.join(sorted(string));
}



with entry {
    print(get_sorted_string('hello'));
    print(get_sorted_string('Racecar'));
    print(get_sorted_string('abcabc'));
}
