def remove_special_chars(string: Any) -> object {
    result = "";
    for char in string {
        if char.isalnum() {
            result += char.lower();
        }
    }
    return result;
}



with entry {
    print(remove_special_chars('hello'));
    print(remove_special_chars('Racecar'));
    print(remove_special_chars('abcabc'));
}
