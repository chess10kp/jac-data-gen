def double_and_sort(arr: Any) -> object {
    result = [];
    for num in arr {
        result.append((num * 2));
    }
    result.sort();
    return result;
}



with entry {
    print(double_and_sort('hello'));
    print(double_and_sort('Racecar'));
    print(double_and_sort('abcabc'));
}
