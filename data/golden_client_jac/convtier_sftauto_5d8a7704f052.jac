def convert_strings_to_floats(strings: Any) -> object {
    floats = [];
    for string in strings {
        try {
            float_value = float(string);
            if float_value.is_integer() {
                floats.append(int(float_value));
            } else {
                floats.append((int(float_value) + 1));
            }
        } except ValueError {
            ;
        }
    }
    return floats;
}



with entry {
    print(convert_strings_to_floats('hello'));
    print(convert_strings_to_floats([81]));
    print(convert_strings_to_floats([100]));
}
