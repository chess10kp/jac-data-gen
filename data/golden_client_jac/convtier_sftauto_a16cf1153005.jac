def sum_of_squares(arr: Any) -> object {
    total_sum = 0;
    for num in arr {
        if (isinstance(num, int) and (num > 0)) {
            total_sum += num ** 2;
        }
    }
    return total_sum;
}



with entry {
    print(sum_of_squares('hello'));
    print(sum_of_squares([81]));
    print(sum_of_squares([100]));
}
