def fibonacci(n: Any) -> object {
    phi = (1 + (5 ** 0.5)) / 2;
    return round((((phi ** n) - (-phi ** -n)) / (5 ** 0.5)));
}



with entry {
    print(fibonacci(5));
    print(fibonacci(10));
    print(fibonacci(2));
}
