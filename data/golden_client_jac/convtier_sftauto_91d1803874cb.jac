def isPrime(num: Any) -> object {
    if (num <= 1) {
        return False;
    }
    if (num == 2) {
        return True;
    }
    if ((num % 2) == 0) {
        return False;
    }
    for i in range(3, (int(math.sqrt(num)) + 1), 2) {
        if ((num % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(isPrime(10));
    print(isPrime(2));
}
