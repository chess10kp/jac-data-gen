def fib(n: Any) -> object {
    if (n <= 0) {
        return "N should be a positive integer";
    } elif (n == 1) {
        return 0;
    } elif (n == 2) {
        return 1;
    } else {
        return (fib((n - 1)) + fib((n - 2)));
    }
}



with entry {
    print(fib(2));
    print(fib(0));
    print(fib(1));
}
