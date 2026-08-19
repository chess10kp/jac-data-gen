def flatten_list(lst: Any) -> object {
    flattened = [];
    for item in lst {
        if isinstance(item, `list) {
            flattened.extend(flatten_list(item));
        } else {
            flattened.append(item);
        }
    }
    return flattened;
}



with entry {
    print(flatten_list('hello'));
    print(flatten_list('Racecar'));
    print(flatten_list('abcabc'));
}
