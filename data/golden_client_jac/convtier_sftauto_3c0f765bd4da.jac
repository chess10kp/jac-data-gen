def collapse_and_sort_string(input_str: Any) -> object {
    output = "";
    prev_char = None;
    for char in input_str {
        if (char == prev_char) {
            continue;
        }
        output += char;
        prev_char = char;
    }
    return "".join(sorted(output));
}



with entry {
    print(collapse_and_sort_string('hello'));
    print(collapse_and_sort_string('Racecar'));
    print(collapse_and_sort_string('abcabc'));
}
