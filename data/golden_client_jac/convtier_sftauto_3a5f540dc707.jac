def calculate_product(numbers: Any) -> object {
    product = 1;
    for num in numbers {
        product *= num;
    }
    return product;
}



with entry {
    print(calculate_product([]));
}
