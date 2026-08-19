def is_prime(n: Any) -> object {
    if ((n < 2) or (n > (10 ** 18))) {
        return "Input must be between 2 and 10^18, inclusive.";
    } elif (n > (10 ** 9)) {
        return False;
    }
    for i in range(2, (int(math.sqrt(n)) + 1)) {
        if ((n % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(is_prime(0));
}
