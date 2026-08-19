def multiply_array(arr: Any) -> object {
    result = [];
    for num in arr {
        multiplied = 1;
        for i in arr {
            multiplied *= i;
        }
        result.append((multiplied // num));
    }
    return result;
}



with entry {
    print(multiply_array([]));
}
