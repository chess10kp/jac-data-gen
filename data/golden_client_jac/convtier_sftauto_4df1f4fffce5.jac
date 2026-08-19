def factorial(n: Any) -> object {
    if (n < 0) {
        return "Error: Input must be a positive integer.";
    } elif (n == 0) {
        return 1;
    } else {
        return (n * factorial((n - 1)));
    }
}



with entry {
    print(factorial(0));
}
