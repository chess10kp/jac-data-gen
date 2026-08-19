def fun(n: Any) -> object {
    a = 0;
    b = 1;
    for _ in range(n) {
        temp = a;
        a = b;
        b = temp + b;
    }
    return a;
}



with entry {
    print(fun(5));
    print(fun(10));
    print(fun(2));
}
