def fibonacci(n: Any) -> object {
    if (n == 0) {
        return 0;
    } elif (n == 1) {
        return 1;
    } else {
        a = 0;
        b = 1;
        for i in range(2, (n + 1)) {
            c = a + b;
            a = b;
            b = c;
        }
        return b;
    }
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
