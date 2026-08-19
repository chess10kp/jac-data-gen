def factorial(n: Any) -> object {
    result = 1;
    for i in range(1, (n + 1)) {
        result = multiply(result, i);
    }
    return result;
}



with entry {
    print(factorial(0));
}
