def modify_string(string: Any) -> object {
    vowels = ['a', 'e', 'i', 'o', 'u'];
    modified_string = '';
    for char in string[::-1] {
        if (char.lower() in vowels) {
            modified_string += char.upper();
        } else {
            modified_string += char.lower();
        }
    }
    return modified_string;
}



with entry {
    print(modify_string('hello'));
    print(modify_string('Racecar'));
    print(modify_string('abcabc'));
}
