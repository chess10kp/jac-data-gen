def find_max_index(arr: Any) -> object {
    if (arr == []) {
        raise EmptyArrayError("Array is empty");
    }
    if `any((num < 0) for num in arr) {
        raise NegativeNumberError("Array contains negative numbers");
    }
    max_num = max(arr);
    return arr.index(max_num);
}



with entry {
    print(find_max_index([4, 2, 1]));
    print(find_max_index([10, 20, 30]));
    print(find_max_index([2, 4, 6, 8]));
}
