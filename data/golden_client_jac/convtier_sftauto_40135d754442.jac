def deep_copy_nested_list(nested_list: Any) -> object {
    if not isinstance(nested_list, `list) {
        return nested_list;
    }
    copy_list = [];
    for item in nested_list {
        if isinstance(item, `list) {
            copy_list.append(deep_copy_nested_list(item));
        } else {
            copy_list.append(item);
        }
    }
    return copy_list;
}



with entry {
    print(deep_copy_nested_list('hello'));
    print(deep_copy_nested_list('Racecar'));
    print(deep_copy_nested_list('abcabc'));
}
