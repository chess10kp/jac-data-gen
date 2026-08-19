def factorial(n: Any) -> object {
    if (n < 0) {
        raise ValueError("Factorial is not defined for negative numbers.");
    } elif (n == 0) {
        return 1;
    } else {
        return (n * factorial((n - 1)));
    }
}



with entry {
    print(factorial(0));
}
