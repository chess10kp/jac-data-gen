def fibonacci(n: Any) -> object {
    if (n == 0) {
        return 0;
    } elif (n == 1) {
        return 1;
    }
    return (fibonacci((n - 1)) + fibonacci((n - 2)));
}



with entry {
    print(fibonacci(0));
    print(fibonacci(1));
}
