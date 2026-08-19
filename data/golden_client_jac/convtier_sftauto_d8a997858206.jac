def square_array(arr: Any) -> object {
    result = [];
    for num in arr {
        square = num ** 2;
        result.append(`abs(square));
    }
    return result;
}



with entry {
    print(square_array([]));
}
