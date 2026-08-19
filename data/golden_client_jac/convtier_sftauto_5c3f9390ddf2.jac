def move_element_to_beginning(lst: Any) -> object {
    if (len(lst) >= 2) {
        second_to_last = lst[-2];
        lst.insert(0, second_to_last);
        lst.pop(-2);
    }
    return lst;
}



with entry {
    print(move_element_to_beginning([]));
}
