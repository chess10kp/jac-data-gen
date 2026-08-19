def fibonacci_sequence(N: Any) -> object {
    if (N <= 0) {
        return [];
    } elif (N == 1) {
        return [0];
    } elif (N == 2) {
        return [0, 1];
    } else {
        sequence = fibonacci_sequence((N - 1));
        sequence.append((sequence[-1] + sequence[-2]));
        return sequence[:N];
    }
}



with entry {
    print(fibonacci_sequence(2));
    print(fibonacci_sequence(0));
    print(fibonacci_sequence(1));
}
