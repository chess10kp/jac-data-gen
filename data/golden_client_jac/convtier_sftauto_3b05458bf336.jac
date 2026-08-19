def remove_duplicates(input_array: Any) -> object {
    unique_array = [];
    for num in input_array {
        if (num not in unique_array) {
            unique_array.append(num);
        }
    }
    return unique_array;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
