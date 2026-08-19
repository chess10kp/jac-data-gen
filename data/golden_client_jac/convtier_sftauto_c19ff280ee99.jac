def convert_to_camel_case(string: Any) -> object {
    if not (
        `any(char.isupper() for char in string)
        and `any(char.isdigit() for char in string)
        and re.search('[^a-zA-Z0-9]', string)
    ) {
        return string;
    }
    string = re.sub('[_-]', ' ', string);
    string = ''.join(word.capitalize() for word in string.split());
    return re.sub('[^a-zA-Z0-9]', '', string);
}



with entry {
    print(convert_to_camel_case('hello'));
    print(convert_to_camel_case('Racecar'));
    print(convert_to_camel_case('abcabc'));
}
