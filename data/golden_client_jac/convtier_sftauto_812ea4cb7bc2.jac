def sum_array_elements(arr: Any) -> object {
    result = 0;
    for i in range(len(arr)) {
        result += arr[i];
    }
    return result;
}



with entry {
    print(sum_array_elements([]));
}
