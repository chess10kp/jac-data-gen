def is_prime(n: Any) -> object {
    if (n == 2) {
        return True;
    } elif ((n % 2) == 0) {
        return False;
    } else {
        for i in range(2, (int((n ** 0.5)) + 1)) {
            if ((n % i) == 0) {
                return False;
            }
        }
        return True;
    }
}



with entry {
    print(is_prime(5));
    print(is_prime(10));
}
