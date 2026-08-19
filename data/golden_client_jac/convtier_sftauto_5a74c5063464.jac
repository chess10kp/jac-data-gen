def convert_string_to_list(input_string: Any) -> object {
    input_string = input_string.strip();
    if not input_string {
        return [];
    }
    elements = input_string.split(",");
    unique_elements = `set(elements);
    return `list(unique_elements);
}



with entry {
    print(convert_string_to_list('hello'));
    print(convert_string_to_list('Racecar'));
    print(convert_string_to_list('abcabc'));
}
