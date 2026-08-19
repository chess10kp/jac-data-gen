def repeat_last_two(string: Any) -> object {
    last_two_chars = string[-2:];
    return (string + last_two_chars);
}



with entry {
    print(repeat_last_two('hello'));
    print(repeat_last_two('Racecar'));
    print(repeat_last_two('abcabc'));
}
