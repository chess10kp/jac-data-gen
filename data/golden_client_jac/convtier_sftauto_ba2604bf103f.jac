def get_odd_numbers(input_list: Any) -> object {
    output_list = [];
    for num in input_list {
        if ((num % 2) != 0) {
            output_list.append(num);
        }
    }
    return output_list;
}



with entry {
    print(get_odd_numbers([]));
}
