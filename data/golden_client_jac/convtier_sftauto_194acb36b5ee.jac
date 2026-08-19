def replace_characters(string: Any) -> object {
    mapping = {'A': 'Z', 'B': 'Y', 'C': 'X', 'D': 'W'};
    result = '';
    for char in string {
        if (char.upper() in mapping) {
            if char.isupper() {
                result += mapping[char.upper()];
            } else {
                result += mapping[char.upper()].lower();
            }
        } else {
            result += char;
        }
    }
    return result;
}



with entry {
    print(replace_characters('hello'));
    print(replace_characters('Racecar'));
    print(replace_characters('abcabc'));
}
