def fibonacci_sequence(n: Any) -> object {
    sequence = [0, 1];
    while (len(sequence) < n) {
        next_num = sequence[-1] + sequence[-2];
        sequence.append(next_num);
    }
    return sequence;
}



with entry {
    print(fibonacci_sequence(5));
    print(fibonacci_sequence(10));
    print(fibonacci_sequence(2));
}
