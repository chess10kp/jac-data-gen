def square_root(number: Any) -> object {
    x = number / 2;
    max_iterations = 1000;
    for _ in range(max_iterations) {
        x = (x + (number / x)) / 2;
    }
    return x;
}



with entry {
    print(square_root(5));
    print(square_root(10));
    print(square_root(2));
}
