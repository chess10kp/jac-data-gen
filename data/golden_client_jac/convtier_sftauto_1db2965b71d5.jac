def is_prime_palindrome(n: Any) -> object {
    if (n < 2) {
        return False;
    }
    if (n == 2) {
        return True;
    }
    if ((n % 2) == 0) {
        return False;
    }
    if (str(n) != str(n)[::-1]) {
        return False;
    }
    for i in range(3, (int((n ** 0.5)) + 1)) {
        if ((n % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime_palindrome(5));
    print(is_prime_palindrome(10));
}
