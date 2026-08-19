def to_camel_case(string: Any) -> object {
    if `any(letter.isupper() for letter in string) {
        words = string.split('_');
        return (words[0] + ''.join(word.capitalize() for word in words[1:]));
    } else {
        return string;
    }
}



with entry {
    print(to_camel_case('hello'));
    print(to_camel_case('Racecar'));
    print(to_camel_case('abcabc'));
}
