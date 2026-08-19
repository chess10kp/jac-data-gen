def fibonacci_recursive(n: Any) -> object {
    if (n <= 0) {
        return [];
    } elif (n == 1) {
        return [0];
    } elif (n == 2) {
        return [0, 1];
    } else {
        series = fibonacci_recursive((n - 1));
        series.append((series[-1] + series[-2]));
        return series;
    }
}



with entry {
    print(fibonacci_recursive(2));
    print(fibonacci_recursive(0));
    print(fibonacci_recursive(1));
}
