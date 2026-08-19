def reverse_string(input_string: Any) -> object {
    if (len(input_string) <= 1) {
        return input_string;
    } else {
        first_char = input_string[0];
        rest_of_string = input_string[1:];
        reversed_rest = reverse_string(rest_of_string);
        return (reversed_rest + first_char);
    }
}



with entry {
    print(reverse_string([81]));
    print(reverse_string([]));
    print(reverse_string(['a']));
}
