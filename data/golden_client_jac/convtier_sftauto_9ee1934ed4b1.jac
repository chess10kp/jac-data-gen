def fibonacci(n: Any) -> object {
    if (n <= 0) {
        return [];
    } elif (n == 1) {
        return [0];
    } elif (n == 2) {
        return [0, 1];
    } else {
        sequence = fibonacci((n - 1));
        sequence.append((sequence[-1] + sequence[-2]));
        return sequence;
    }
}



with entry {
    print(fibonacci(2));
    print(fibonacci(0));
    print(fibonacci(1));
}
