def transform_string(string: Any) -> object {
    transformed_string = "";
    for char in string {
        if (char == char.lower()) {
            transformed_string += char.upper();
        } else {
            transformed_string += char.lower();
        }
    }
    return transformed_string;
}



with entry {
    print(transform_string('hello'));
    print(transform_string('Racecar'));
    print(transform_string('abcabc'));
}
