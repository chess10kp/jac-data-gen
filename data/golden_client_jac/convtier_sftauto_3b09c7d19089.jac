def fibonacci(n: Any) -> object {
    if (n <= 0) {
        return "Invalid input. Please enter a positive integer.";
    } elif (n == 1) {
        return 0;
    } elif (n == 2) {
        return 1;
    } else {
        return (fibonacci((n - 1)) + fibonacci((n - 2)));
    }
}



with entry {
    print(fibonacci(2));
    print(fibonacci(0));
    print(fibonacci(1));
}
