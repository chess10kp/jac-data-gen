def is_prime(n: int) -> bool {
    if n < 2 {
        return False;
    }
    i = 2;
    while i * i <= n {
        if n % i == 0 {
            return False;
        }
        i += 1;
    }
    return True;
}

with entry {
    for x in [1, 2, 15, 17, 97] {
        print(is_prime(x));
    }
}
