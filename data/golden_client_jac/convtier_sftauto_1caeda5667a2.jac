def sum_of_squares(arr: Any) -> object {
    result = 0;
    for num in arr {
        for _ in range(num) {
            result += num;
        }
    }
    return result;
}



with entry {
    print(sum_of_squares([]));
}
