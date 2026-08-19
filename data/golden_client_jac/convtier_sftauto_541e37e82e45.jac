def sum_of_squares(arr: Any) -> object {
    sum = 0;
    for num in arr {
        if (num > 0) {
            sum += num ** 2;
        }
    }
    return sum;
}



with entry {
    print(sum_of_squares([81]));
    print(sum_of_squares([]));
    print(sum_of_squares([100]));
}
