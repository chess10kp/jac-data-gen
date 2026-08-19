def strip_and_reverse_string(string: Any) -> object {
    stripped_string = string.strip();
    stripped_string = ''.join(
        char
        for char in stripped_string
        if (char.isspace() or not char.isalnum())
    );
    reversed_string = stripped_string[::-1];
    return reversed_string;
}



with entry {
    print(strip_and_reverse_string('hello'));
    print(strip_and_reverse_string('Hello, World!'));
    print(strip_and_reverse_string('step on no pets'));
}
