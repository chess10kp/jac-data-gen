def flatten_array(arr: Any) -> object {
    if not arr {
        return [];
    }
    result = [];
    for element in arr {
        if isinstance(element, `list) {
            result.extend(flatten_array(element));
        } else {
            result.append(element);
        }
    }
    return result;
}



with entry {
    print(flatten_array('hello'));
    print(flatten_array('Racecar'));
    print(flatten_array('abcabc'));
}
