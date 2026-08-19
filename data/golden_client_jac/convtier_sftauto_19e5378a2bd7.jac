def snake_to_camel(snake_case: Any) -> object {
    words = snake_case.split('_');
    camel_case = words[0];
    for word in words[1:] {
        camel_case += word.capitalize();
    }
    return camel_case;
}



with entry {
    print(snake_to_camel('hello'));
    print(snake_to_camel('Racecar'));
    print(snake_to_camel('abcabc'));
}
