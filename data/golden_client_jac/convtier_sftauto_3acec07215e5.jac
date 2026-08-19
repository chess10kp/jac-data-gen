def remove_duplicates(lst: Any) -> object {
    updated_lst = [];
    for i in lst {
        if (i not in updated_lst) {
            updated_lst.append(i);
        }
    }
    return updated_lst;
}



with entry {
    print(remove_duplicates('hello'));
    print(remove_duplicates('Racecar'));
    print(remove_duplicates('abcabc'));
}
