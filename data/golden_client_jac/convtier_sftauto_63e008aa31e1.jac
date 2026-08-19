def factorial(n: Any) -> object {
    if (not isinstance(n, int) or (n < 0)) {
        return "Error: Input should be a positive integer.";
    } elif (n == 0) {
        return 1;
    } else {
        return (n * factorial((n - 1)));
    }
}



with entry {
    print(factorial('hello'));
    print(factorial(0));
}
