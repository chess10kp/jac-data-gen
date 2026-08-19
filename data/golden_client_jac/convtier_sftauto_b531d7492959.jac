def get_divisors(n: Any) -> object {
    divisors = [];
    for i in range(1, (n + 1)) {
        if ((n % i) == 0) {
            divisors.append(i);
        }
    }
    return divisors;
}



with entry {
    print(get_divisors(5));
    print(get_divisors(10));
    print(get_divisors(2));
}
