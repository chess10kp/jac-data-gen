def is_prime(n: Any) -> object {
    if ((n < 2) or not isinstance(n, int)) {
        return "Not Prime";
    }
    for i in range(2, (math.isqrt(n) + 1)) {
        if ((n % i) == 0) {
            return "Not Prime";
        }
    }
    return "Prime";
}



with entry {
    print(is_prime(0));
}
