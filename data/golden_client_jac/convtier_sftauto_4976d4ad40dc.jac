def sum_of_squares(arr: Any) -> object {
    total_sum = 0;
    for num in arr {
        if isinstance(num, int) {
            total_sum += num ** 2;
        }
    }
    return total_sum;
}



with entry {
    print(sum_of_squares('hello'));
}
