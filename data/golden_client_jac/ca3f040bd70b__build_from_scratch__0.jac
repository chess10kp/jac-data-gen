def fibonacci(n: int) -> int {
    a = 0;
    b = 1;
    i = 0;
    while i < n {
        t = a + b;
        a = b;
        b = t;
        i += 1;
    }
    return a;
}

with entry {
    for x in [0, 1, 2, 10, 20] {
        print(fibonacci(x));
    }
}
