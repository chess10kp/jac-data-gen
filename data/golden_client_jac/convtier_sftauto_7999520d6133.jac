def square(x: Any) -> object {
    return (x ** 2) if (x > 0) else 0;
}



with entry {
    print(square(5));
    print(square(10));
    print(square(2));
}
