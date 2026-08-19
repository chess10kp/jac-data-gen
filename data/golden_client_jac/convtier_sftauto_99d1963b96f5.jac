def reverse_list(lst: Any) -> object {
    reversed_lst = [];
    for i in range((len(lst) - 1), -1, -1) {
        reversed_lst.append(lst[i]);
    }
    return reversed_lst;
}



with entry {
    print(reverse_list('hello'));
    print(reverse_list('Racecar'));
    print(reverse_list('abcabc'));
}
