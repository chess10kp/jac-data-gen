def filter_divisible(arr: Any) -> object {
    result = [];
    for num in arr {
        if (((num % 3) == 0) and ((num % 7) == 0)) {
            result.append(num);
        }
    }
    return result;
}



with entry {
    print(filter_divisible([]));
}
