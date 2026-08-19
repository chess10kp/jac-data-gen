def flatten_list(lst: Any) -> object {
    flattened_list = [];
    for sublist in lst {
        for element in sublist {
            if (element not in flattened_list) {
                flattened_list.append(element);
            }
        }
    }
    return flattened_list;
}



with entry {
    print(flatten_list('hello'));
    print(flatten_list('Racecar'));
    print(flatten_list('abcabc'));
}
