def transform_to_uppercase(string: Any) -> object {
    modified_string = "";
    for char in string {
        if char.isalpha() {
            if ((char >= 'a') and (char <= 'z')) {
                char = chr((ord(char) - 32));
            } elif ((char >= 'à') and (char <= 'ÿ')) {
                char = chr((ord(char) - 32));
            }
        }
        modified_string += char;
    }
    return modified_string;
}



with entry {
    print(transform_to_uppercase('hello'));
    print(transform_to_uppercase('Racecar'));
    print(transform_to_uppercase('abcabc'));
}
