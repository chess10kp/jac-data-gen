def factorial(num: Any) -> object {
    result = 1;
    for i in range(1, (num + 1)) {
        result *= i;
    }
    return result;
}



with entry {
    print(factorial(5));
    print(factorial(10));
    print(factorial(2));
}
