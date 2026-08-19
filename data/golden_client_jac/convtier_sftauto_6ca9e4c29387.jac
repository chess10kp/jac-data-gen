def find_median(lst: Any) -> object {
    if not lst {
        return None;
    }
    sorted_lst = sorted(lst);
    if ((len(sorted_lst) % 2) == 1) {
        return sorted_lst[(len(sorted_lst) // 2)];
    } else {
        mid1 = sorted_lst[(len(sorted_lst) // 2)];
        mid2 = sorted_lst[((len(sorted_lst) // 2) - 1)];
        return ((mid1 + mid2) / 2);
    }
}



with entry {
    print(find_median('hello'));
    print(find_median('Racecar'));
    print(find_median('Hello, World!'));
}
