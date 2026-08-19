def calculate_product(n: Any) -> object {
    product = 1;
    for i in range(1, (n + 1)) {
        product *= i;
    }
    return (product * 3);
}



with entry {
    print(calculate_product(5));
    print(calculate_product(10));
    print(calculate_product(2));
}
