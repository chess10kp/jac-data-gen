def calculate_pi(n: Any) -> object {
    pi = 0;
    sign = 1;
    denominator = 1;
    for i in range(n) {
        pi += sign * (4 / denominator);
        sign *= -1;
        denominator += 2;
    }
    return round(pi, n);
}



with entry {
    print(calculate_pi(5));
    print(calculate_pi(10));
    print(calculate_pi(2));
}
