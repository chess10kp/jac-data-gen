def fibonacci(n: Any) -> object {
    if (n == 0) {
        return [];
    } elif (n == 1) {
        return [0];
    } elif (n == 2) {
        return [0, 1];
    }
    fib_seq = [0, 1];
    for i in range(2, n) {
        fib_seq.append((fib_seq[(i - 1)] + fib_seq[(i - 2)]));
    }
    return fib_seq;
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
