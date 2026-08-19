def is_prime_and_palindrome(n: Any) -> object {
    if (n < 2) {
        return False;
    }
    for i in range(2, (int(math.sqrt(n)) + 1)) {
        if ((n % i) == 0) {
            return False;
        }
    }
    if (str(n) == str(n)[::-1]) {
        return True;
    }
    return False;
}



with entry {
    print(is_prime_and_palindrome(0));
}
