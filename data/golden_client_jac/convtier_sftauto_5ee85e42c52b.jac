def modify_string(text: Any) -> object {
    vowels = "aeiou";
    modified_text = "";
    previous_char = "";
    for char in text {
        if (char.lower() in vowels) {
            if ((char.lower() != previous_char.lower()) or char.isupper()) {
                modified_text += char.upper();
            }
            previous_char = char;
        } else {
            modified_text += char.lower();
            previous_char = "";
        }
    }
    return modified_text;
}



with entry {
    print(modify_string('hello'));
    print(modify_string('Racecar'));
    print(modify_string('abcabc'));
}
