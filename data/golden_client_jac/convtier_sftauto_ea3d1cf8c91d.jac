def process_string(input_string: Any) -> object {
    result = "";
    for i in range((len(input_string) - 1), -1, -1) {
        c = input_string[i];
        if (c not in ['a', 'e', 'i', 'o', 'u']) {
            result += c;
        }
    }
    result = result[::-1];
    result = result.replace(' ', '*');
    return result;
}



with entry {
    print(process_string('hello'));
    print(process_string('Racecar'));
    print(process_string('abcabc'));
}
