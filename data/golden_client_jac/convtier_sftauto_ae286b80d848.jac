def generate_fibonacci_series(n: Any) -> object {
    if (not isinstance(n, int) or (n <= 0) or (n > 50)) {
        raise ValueError("n must be a positive integer between 1 and 50");
    }
    series = [];
    (a, b) = (0, 1);
    for _ in range(n) {
        series.append(a);
        (a, b) = (b, (a + b));
    }
    return series;
}



with entry {
    print(generate_fibonacci_series(5));
    print(generate_fibonacci_series(10));
    print(generate_fibonacci_series(2));
}
