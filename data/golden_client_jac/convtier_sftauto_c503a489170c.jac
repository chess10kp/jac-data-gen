def generate_fibonacci_sequence(n: Any) -> object {
    fibonacci_sequence = [0, 1];
    if (n < 2) {
        return fibonacci_sequence[:(n + 1)];
    }
    while ((fibonacci_sequence[-1] + fibonacci_sequence[-2]) <= n) {
        next_number = fibonacci_sequence[-1] + fibonacci_sequence[-2];
        fibonacci_sequence.append(next_number);
    }
    return fibonacci_sequence;
}



with entry {
    print(generate_fibonacci_sequence(5));
    print(generate_fibonacci_sequence(10));
    print(generate_fibonacci_sequence(2));
}
