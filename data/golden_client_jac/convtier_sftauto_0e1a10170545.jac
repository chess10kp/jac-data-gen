def calculate_factorial(n: Any) -> object {
    if (n < 0) {
        raise ValueError("Factorial of a negative number is not allowed.");
    } elif (n == 0) {
        return 1;
    } else {
        return (n * calculate_factorial((n - 1)));
    }
}



with entry {
    print(calculate_factorial(0));
}
