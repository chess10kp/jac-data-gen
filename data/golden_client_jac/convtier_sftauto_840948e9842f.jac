def isOddPrimeGreaterThan100(number: Any) -> object {
    if ((number <= 100) or ((number % 2) == 0)) {
        return False;
    }
    for i in range(3, (int((number ** 0.5)) + 1), 2) {
        if ((number % i) == 0) {
            return False;
        }
    }
    return True;
}



with entry {
    print(isOddPrimeGreaterThan100(5));
}
