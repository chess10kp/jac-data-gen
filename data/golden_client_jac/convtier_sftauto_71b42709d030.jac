def reverse_alphanumeric(input_string: Any) -> object {
    alphanumeric_string = ''.join(
        c.lower()
        for c in input_string
        if c.isalnum()
    );
    reversed_string = alphanumeric_string[::-1];
    return reversed_string;
}



with entry {
    print(reverse_alphanumeric('hello'));
    print(reverse_alphanumeric('Racecar'));
    print(reverse_alphanumeric('abcabc'));
}
