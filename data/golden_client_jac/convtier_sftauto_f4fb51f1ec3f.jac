def flatten_and_sort(two_d_list: Any) -> object {
    flattened_list = [];
    for sublist in two_d_list {
        for element in sublist {
            if (element not in flattened_list) {
                flattened_list.append(element);
            }
        }
    }
    flattened_list.sort();
    return flattened_list;
}



with entry {
    print(flatten_and_sort('hello'));
    print(flatten_and_sort('Racecar'));
    print(flatten_and_sort('abcabc'));
}
