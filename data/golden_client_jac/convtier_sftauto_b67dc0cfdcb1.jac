def calculate_series_sum(N: Any) -> object {
    if (N <= 0) {
        raise ValueError("N must be a positive integer.");
    }
    series_sum = 0;
    factorial = 1;
    for i in range(1, (N + 1)) {
        factorial *= i;
        series_sum += 1 / factorial;
    }
    return series_sum;
}



with entry {
    print(calculate_series_sum(5));
    print(calculate_series_sum(10));
    print(calculate_series_sum(2));
}
