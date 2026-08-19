def factorial(n: Any) -> object {
    if ((n == 0) or (n == 1)) {
        return 1;
    } elif (n < 0) {
        return "Factorial is not defined for negative numbers.";
    } else {
        return (n * factorial((n - 1)));
    }
}



with entry {
    print(factorial(0));
}
