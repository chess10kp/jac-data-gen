def extract_characters(string: Any) -> object {
    cleaned_string = ''.join(
        char.lower()
        for char in string
        if (char.isalpha() and char.islower())
    );
    unique_chars = [];
    for char in cleaned_string {
        if (char not in unique_chars) {
            unique_chars.append(char);
        }
    }
    return sorted(unique_chars);
}



with entry {
    print(extract_characters('hello'));
    print(extract_characters('Racecar'));
    print(extract_characters('abcabc'));
}
