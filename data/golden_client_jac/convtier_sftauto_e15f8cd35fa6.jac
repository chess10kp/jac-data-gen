def flatten_and_filter(arr: Any) -> object {
    result = [];
    for elem in arr {
        if isinstance(elem, `list) {
            result.extend(flatten_and_filter(elem));
        } elif (isinstance(elem, int) and ((elem % 2) == 0) and ((elem % 3) == 0)) {
            result.append(elem);
        }
    }
    result.sort();
    return result;
}



with entry {
    print(flatten_and_filter('hello'));
    print(flatten_and_filter([10, 20, 30]));
    print(flatten_and_filter([2, 4, 6, 8]));
}
