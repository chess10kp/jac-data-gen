def factorial2(n: Any) -> object {
    if (n == 0) {
        return 1;
    } else {
        return (n * factorial2((n - 1)));
    }
}



with entry {
    print(factorial2(0));
}
