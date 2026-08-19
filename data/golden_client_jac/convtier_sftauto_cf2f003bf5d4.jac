def calculate_series_sum(n: Any) -> object {
    if (not isinstance(n, int) or (n <= 1)) {
        return "Error: n must be a positive integer greater than 1.";
    }
    sum_of_series = (n * (n + 1)) // 2;
    return sum_of_series;
}



with entry {
    print(calculate_series_sum('hello'));
    print(calculate_series_sum(5));
    print(calculate_series_sum(10));
}
