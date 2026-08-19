def flatten_list(lst: Any) -> object {
    flattened_list = [];
    for item in lst {
        if isinstance(item, `list) {
            flattened_list.extend(flatten_list(item));
        } elif isinstance(item, int) {
            flattened_list.append(item);
        }
    }
    return flattened_list;
}



with entry {
    print(flatten_list('hello'));
}
