def remove_first_and_last_occurrence(string: Any) -> object {
    lowercase_letters = [
        char
        for char in string
        if char.islower()
    ];
    result = "";
    for char in string {
        if (char.islower() and (lowercase_letters.count(char) > 1)) {
            lowercase_letters.remove(char);
            if (lowercase_letters.count(char) > 1) {
                lowercase_letters.remove(char);
                result += char;
            }
        } else {
            result += char;
        }
    }
    return result;
}



with entry {
    print(remove_first_and_last_occurrence('hello'));
    print(remove_first_and_last_occurrence('Racecar'));
    print(remove_first_and_last_occurrence('abcabc'));
}
