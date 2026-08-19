def convert_nested_list_to_dict(nested_list: Any) -> object {
    nested_dict = {};
    for item in nested_list {
        key = item[0];
        value = item[1];
        if isinstance(value, `dict) {
            nested_dict[key] = convert_nested_dict(value);
        } else {
            nested_dict[key] = value;
        }
    }
    return nested_dict;
}



with entry {
    print(convert_nested_list_to_dict([]));
}
