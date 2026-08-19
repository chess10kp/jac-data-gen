def move_second_to_beginning(lst: Any) -> object {
    if (len(lst) < 2) {
        return lst;
    }
    second_last = lst[-2];
    for i in range((len(lst) - 2), 0, -1) {
        lst[i] = lst[(i - 1)];
    }
    lst[0] = second_last;
    return lst;
}



with entry {
    print(move_second_to_beginning([-9]));
    print(move_second_to_beginning([]));
    print(move_second_to_beginning(['a']));
}
