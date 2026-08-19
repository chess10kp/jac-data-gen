def get_list_length(lst: Any) -> object {
    count = 0;
    for _ in lst {
        count += 1;
    }
    return count;
}



with entry {
    print(get_list_length('hello'));
    print(get_list_length('Racecar'));
    print(get_list_length('abcabc'));
}
