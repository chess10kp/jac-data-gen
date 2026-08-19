def round_and_format(numbers: Any) -> object {
    rounded_strings = [];
    for number in numbers {
        rounded_number = round(number, 3);
        rounded_string = '{:.3f}'.format(rounded_number);
        rounded_strings.append(rounded_string);
    }
    return sorted(rounded_strings);
}



with entry {
    print(round_and_format([]));
}
