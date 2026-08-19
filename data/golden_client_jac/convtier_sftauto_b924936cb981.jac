def fibonacci_sequence(num_elements: Any) -> object {
    sequence = [0, 1];
    for i in range(2, num_elements) {
        next_num = sequence[(i - 1)] + sequence[(i - 2)];
        sequence.append(next_num);
    }
    return sequence;
}



with entry {
    print(fibonacci_sequence(5));
    print(fibonacci_sequence(10));
    print(fibonacci_sequence(2));
}
