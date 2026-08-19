def fibonacci_sequence(N: Any) -> object {
    if (N <= 0) {
        return [];
    }
    sequence = [0, 1];
    while ((sequence[-1] + sequence[-2]) <= N) {
        next_number = sequence[-1] + sequence[-2];
        sequence.append(next_number);
    }
    return sequence;
}



with entry {
    print(fibonacci_sequence(5));
    print(fibonacci_sequence(10));
    print(fibonacci_sequence(2));
}
