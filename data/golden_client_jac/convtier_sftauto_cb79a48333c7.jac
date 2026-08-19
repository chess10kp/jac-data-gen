def flatten_list(nested_list: Any) -> object {
    flattened_list = [];
    for element in nested_list {
        if isinstance(element, `list) {
            flattened_list.extend(flatten_list(element));
        } else {
            flattened_list.append(element);
        }
    }
    return flattened_list;
}



with entry {
    print(flatten_list('hello'));
    print(flatten_list('Racecar'));
    print(flatten_list('abcabc'));
}
