def find_median(lst: Any) -> object {
    lst.sort();
    middle_index = len(lst) // 2;
    if ((len(lst) % 2) == 0) {
        return ((lst[(middle_index - 1)] + lst[middle_index]) / 2);
    } else {
        return lst[middle_index];
    }
}



with entry {
    print(find_median([1, 2, 4]));
    print(find_median([1, 2]));
    print(find_median([5, 5, 5]));
}
