def find_median(lst: Any) -> object {
    if not lst {
        return "Error: The list is empty.";
    }
    sorted_lst = sorted(lst);
    length = len(sorted_lst);
    if ((length % 2) == 1) {
        middle_index = length // 2;
        return sorted_lst[middle_index];
    } else {
        middle_index_1 = (length // 2) - 1;
        middle_index_2 = length // 2;
        return ((sorted_lst[middle_index_1] + sorted_lst[middle_index_2]) / 2);
    }
}



with entry {
    print(find_median('hello'));
    print(find_median('Racecar'));
    print(find_median('Hello, World!'));
}
