def calculate_standard_deviation(temperatures: Any) -> object {
    n = len(temperatures);
    mean = sum(temperatures) / n;
    squared_diff_sum = sum(((x - mean) ** 2) for x in temperatures);
    variance = squared_diff_sum / (n - 1);
    return (variance ** 0.5);
}



with entry {
    print(calculate_standard_deviation([2, 9]));
    print(calculate_standard_deviation([10, 20, 30]));
    print(calculate_standard_deviation([2, 4, 6, 8]));
}
