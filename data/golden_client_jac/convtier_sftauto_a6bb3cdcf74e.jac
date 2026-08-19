def remove_duplicates(arr: Any) -> object {
    unique_array = [];
    for num in arr {
        if (num not in unique_array) {
            unique_array.append(num);
        }
    }
    unique_array.sort();
    return unique_array;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
