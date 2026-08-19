def flatten_array(arr: Any) -> object {
    flat_array = [];
    for sub_array in arr {
        if isinstance(sub_array, `list) {
            flat_array.extend(flatten_array(sub_array));
        } else {
            flat_array.append(sub_array);
        }
    }
    return flat_array;
}



with entry {
    print(flatten_array('hello'));
    print(flatten_array('Racecar'));
    print(flatten_array('abcabc'));
}
