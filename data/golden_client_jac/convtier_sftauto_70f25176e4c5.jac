def extract_characters(input_string: Any) -> object {
    output_string = "";
    for char in input_string {
        if char.isalpha() {
            output_string += char;
        }
    }
    return output_string;
}



with entry {
    print(extract_characters('hello'));
    print(extract_characters('Racecar'));
    print(extract_characters('abcabc'));
}
