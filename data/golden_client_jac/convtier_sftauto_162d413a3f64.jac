def remove_duplicates(original_list: Any) -> object {
    result = [];
    for num in original_list {
        if (num not in result) {
            result.append(num);
        }
    }
    return result;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
