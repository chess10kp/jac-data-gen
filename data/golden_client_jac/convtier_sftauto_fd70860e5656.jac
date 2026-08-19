def fibonacci(n: Any) -> object {
    if (n <= 0) {
        return [];
    } elif (n == 1) {
        return [0];
    } elif (n == 2) {
        return [0, 1];
    } else {
        fib_sequence = [0, 1];
        while (len(fib_sequence) < n) {
            next_number = fib_sequence[-1] + fib_sequence[-2];
            fib_sequence.append(next_number);
        }
        return fib_sequence;
    }
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
