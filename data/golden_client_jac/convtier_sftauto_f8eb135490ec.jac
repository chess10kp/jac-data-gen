def reverse_words(string: Any) -> object {
    start = end=len(string) - 1;
    reversed_string = "";
    while (end >= 0) {
        if (string[end] == " ") {
            reversed_string += string[(start + 1):(end + 1)] + " ";
            start = end;
        }
        end -= 1;
    }
    reversed_string += string[start:(end + 1)];
    return reversed_string;
}



with entry {
    print(reverse_words('hello'));
    print(reverse_words('Hello, World!'));
    print(reverse_words('step on no pets'));
}
