def get_ascii_sum(string: Any) -> object {
    ascii_sum = 0;
    for char in string {
        if char.isalpha() {
            ascii_sum += ord(char);
        }
    }
    return ascii_sum;
}



with entry {
    print(get_ascii_sum('hello'));
    print(get_ascii_sum('Racecar'));
    print(get_ascii_sum('abcabc'));
}
