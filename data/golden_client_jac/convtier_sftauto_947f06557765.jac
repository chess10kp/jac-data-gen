def find_unique_elements(lst: Any) -> object {
    unique_lst = [];
    for num in lst {
        if (num not in unique_lst) {
            unique_lst.append(num);
        }
    }
    return unique_lst;
}



with entry {
    print(find_unique_elements('hello'));
    print(find_unique_elements('Racecar'));
    print(find_unique_elements('abcabc'));
}
