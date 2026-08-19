def add_period(string: Any) -> object {
    string = string.strip();
    if (string[-1].lower() in ['a', 'e', 'i', 'o', 'u']) {
        string += '.';
    }
    return string;
}



with entry {
    print(add_period('hello'));
    print(add_period('Racecar'));
    print(add_period('abcabc'));
}
