def fun(n: Any) -> object {
    if (n <= 0) {
        return 0;
    } elif (n <= 1) {
        return n;
    } else {
        (a, b) = (0, 1);
        for _ in range(2, (n + 1)) {
            (a, b) = (b, (a + b));
        }
        return b;
    }
}



with entry {
    print(fun(5));
    print(fun(10));
    print(fun(2));
}
