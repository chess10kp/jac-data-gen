def concatenate_strings(input_list: Any) -> object {
    result = [];
    total_len = sum(len(s) for s in input_list) - len(input_list);
    for i in range(len(input_list)) {
        concatenated = "";
        for j in range(len(input_list)) {
            if (i != j) {
                concatenated += input_list[j];
            }
        }
        result.append(concatenated);
    }
    return result;
}



with entry {
    print(concatenate_strings('hello'));
    print(concatenate_strings('Racecar'));
    print(concatenate_strings('abcabc'));
}
