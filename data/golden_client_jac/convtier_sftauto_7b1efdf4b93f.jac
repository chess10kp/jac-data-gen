def toggle_string(string: Any) -> object {
    toggled_string = "";
    for char in string {
        if char.isalpha() {
            toggled_string += char.swapcase();
        } else {
            toggled_string += char;
        }
    }
    return toggled_string;
}



with entry {
    print(toggle_string('hello'));
    print(toggle_string('Racecar'));
    print(toggle_string('abcabc'));
}
