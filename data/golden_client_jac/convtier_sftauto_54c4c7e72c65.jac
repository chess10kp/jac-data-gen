def get_unique_elements(lst: Any) -> object {
    unique_lst = [];
    prev = None;
    for num in lst {
        if (num != prev) {
            unique_lst.append(num);
        }
        prev = num;
    }
    return unique_lst;
}



with entry {
    print(get_unique_elements('hello'));
    print(get_unique_elements('Racecar'));
    print(get_unique_elements('abcabc'));
}
