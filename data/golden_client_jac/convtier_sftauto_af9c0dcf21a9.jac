def modify_strings(input_list: Any) -> object {
    result = [];
    for string in input_list {
        if (
            string[0].isupper()
            and all((letter.lower() not in 'aeiou') for letter in string)
        ) {
            result.append(string[::-1]);
        }
    }
    result.sort();
    return result;
}



with entry {
    print(modify_strings('hello'));
    print(modify_strings('Racecar'));
    print(modify_strings('Hello, World!'));
}
