def sum_of_series(n: Any) -> object {
    if (n <= 0) {
        return "Invalid input! n should be a positive integer.";
    } else {
        series_sum = sum([(i ** 4) for i in range(1, (n + 1))]);
        return series_sum;
    }
}



with entry {
    print(sum_of_series(5));
    print(sum_of_series(10));
    print(sum_of_series(2));
}
