def is_prime(n: int) -> bool {
    i = 2;
    while i * i <= n {
        if n % i == 0 { return False; }
        i += 1;
    }
    return True;
}
