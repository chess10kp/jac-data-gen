def factorial(n: Any) -> object {
    if (n < 0) {
        return None;
    } elif (n == 0) {
        return 1;
    } else {
        result = 1;
        for i in range(1, (`abs(n) + 1)) {
            result *= i;
        }
        if (n < 0) {
            return -result;
        } else {
            return result;
        }
    }
}



with entry {
    print(factorial(5));
    print(factorial(10));
    print(factorial(2));
}
