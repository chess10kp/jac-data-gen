def modify_string(string: Any) -> object {
    modified_string = "";
    for char in string {
        if ((char.lower() == 'o') or (char.lower() == 'l')) {
            if char.islower() {
                modified_string += char.upper();
            } else {
                modified_string += char.lower();
            }
        } else {
            modified_string += char;
        }
    }
    return modified_string;
}



with entry {
    print(modify_string('hello'));
    print(modify_string('Racecar'));
    print(modify_string('abcabc'));
}
