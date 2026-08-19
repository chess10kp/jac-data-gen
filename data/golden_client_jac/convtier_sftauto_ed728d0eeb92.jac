def multiply_and_sort(arr: Any) -> object {
    result = [];
    for num in arr {
        result.append((num * 3));
    }
    result.sort(reverse=True);
    return result;
}



with entry {
    print(multiply_and_sort('hello'));
    print(multiply_and_sort('Racecar'));
    print(multiply_and_sort('abcabc'));
}
