def alphabetical_strings(input_list: Any) -> object {
    output_list = [];
    for string in input_list {
        string = string.strip();
        if (len(string) >= 5) {
            sorted_string = ''.join(sorted(`list(string)));
            output_list.append(sorted_string);
        }
    }
    return output_list;
}



with entry {
    print(alphabetical_strings('hello'));
}
