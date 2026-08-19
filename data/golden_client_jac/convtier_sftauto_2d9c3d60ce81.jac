def reverse_digits(number: Any) -> object {
    number_str = str(number);
    if (number < 0) {
        number_str = number_str[1:];
        reversed_str = number_str[::-1];
        reversed_str = '-' + reversed_str;
    } else {
        reversed_str = number_str[::-1];
    }
    reversed_digits = [];
    for char in reversed_str {
        reversed_digits.append(char);
    }
    return reversed_digits;
}



with entry {
    print(reverse_digits(5));
    print(reverse_digits(10));
    print(reverse_digits(2));
}
