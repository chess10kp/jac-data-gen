def replace_zeros(input_list: Any) -> object {
    if isinstance(input_list, `list) {
        for i in range(len(input_list)) {
            if isinstance(input_list[i], `list) {
                input_list[i] = replace_zeros(input_list[i]);
            } elif (input_list[i] == 0) {
                input_list[i] = 1;
            }
        }
    } elif (input_list == 0) {
        input_list = 1;
    }
    return input_list;
}



with entry {
    print(replace_zeros('hello'));
    print(replace_zeros('Racecar'));
    print(replace_zeros('abcabc'));
}
