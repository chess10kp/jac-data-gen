def sort_positive_descending(arr: Any) -> object {
    count_dict = {};
    for num in arr {
        if (num > 0) {
            count_dict[num] = count_dict.get(num, 0) + 1;
        }
    }
    unique_list = [];
    for (key, value) in count_dict.items() {
        unique_list.extend(([key] * value));
    }
    unique_list.sort(reverse=True);
    return unique_list;
}



with entry {
    print(sort_positive_descending([]));
    print(sort_positive_descending([6, -12]));
    print(sort_positive_descending([21, -3, -6, -12]));
}
