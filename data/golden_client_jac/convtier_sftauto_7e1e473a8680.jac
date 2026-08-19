def cubic_function(input_list: Any) -> object {
    result = [];
    n = len(input_list);
    for i in range(n) {
        for j in range(n) {
            for k in range(n) {
                result.append((input_list[i] + input_list[j] + input_list[k]));
            }
        }
    }
    return result;
}



with entry {
    print(cubic_function('hello'));
    print(cubic_function('Racecar'));
    print(cubic_function('abcabc'));
}
