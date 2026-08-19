def ascii_sum(string: Any) -> object {
    return sum(ord(char) for char in string);
}



with entry {
    print(ascii_sum('hello'));
    print(ascii_sum('Racecar'));
    print(ascii_sum('abcabc'));
}
