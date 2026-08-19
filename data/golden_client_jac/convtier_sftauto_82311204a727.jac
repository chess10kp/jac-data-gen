def repeat_characters(string: Any) -> object {
    result = '';
    for char in string {
        if char.isdigit() {
            result += char * 3;
        } else {
            result += char * 2;
        }
    }
    return result;
}



with entry {
    print(repeat_characters('hello'));
    print(repeat_characters('Racecar'));
    print(repeat_characters('abcabc'));
}
