def fibonacci(n: Any) -> object {
    if (n <= 0) {
        return None;
    } elif (n == 1) {
        return 0;
    } elif (n == 2) {
        return 1;
    } else {
        (a, b) = (0, 1);
        for _ in range((n - 2)) {
            (a, b) = (b, (a + b));
        }
        return b;
    }
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
