def fibonacci_sequence(n: Any) -> object {
    sequence = [0, 1];
    for i in range(2, n) {
        next_term = sequence[(i - 1)] + sequence[(i - 2)];
        sequence.append(next_term);
    }
    return sequence;
}



with entry {
    print(fibonacci_sequence(5));
    print(fibonacci_sequence(10));
    print(fibonacci_sequence(2));
}
