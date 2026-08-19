def factorial(n: Any) -> object {
    if (n < 0) {
        return "Invalid input";
    } elif (n == 0) {
        return 1;
    }
    result = 1;
    for i in range(1, (`abs(n) + 1)) {
        result *= i;
    }
    if ((n < 0) and ((n % 2) == 1)) {
        return -result;
    } else {
        return result;
    }
}



with entry {
    print(factorial(5));
    print(factorial(10));
    print(factorial(2));
}
