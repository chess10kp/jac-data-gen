def remove_duplicates(array: Any) -> object {
    unique_array = [];
    for num in array {
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
