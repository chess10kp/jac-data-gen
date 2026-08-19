def isPrime(n: Any) -> object {
    if (n < 2) {
        return False;
    }
    if ((n == 2) or (n == 3)) {
        return True;
    }
    if (((n % 2) == 0) or ((n % 3) == 0)) {
        return False;
    }
    sqrt_n = int(math.sqrt(n));
    for i in range(5, (sqrt_n + 1), 6) {
        if (((n % i) == 0) or ((n % (i + 2)) == 0)) {
            return False;
        }
    }
    return True;
}



with entry {
    print(isPrime(10));
    print(isPrime(2));
}
