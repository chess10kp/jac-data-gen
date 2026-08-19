def remove_duplicates(my_list: Any) -> object {
    unique_list = [];
    for num in my_list {
        if (num not in unique_list) {
            unique_list.append(num);
        }
    }
    return unique_list;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
