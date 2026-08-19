def flatten_array(arr: Any) -> object {
    result = [];
    for element in arr {
        if isinstance(element, `list) {
            if (element and `any(isinstance(e, `list) for e in element)) {
                result.extend(flatten_array(element));
            } elif element {
                result.extend(element);
            }
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
