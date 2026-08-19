def isPowerOfTwo(n: Any) -> object {
    if (n <= 0) {
        return False;
    }
    while (n > 1) {
        if ((n % 2) != 0) {
            return False;
        }
        n = n // 2;
    }
    return True;
}



with entry {
    print(isPowerOfTwo(5));
    print(isPowerOfTwo(2));
}
