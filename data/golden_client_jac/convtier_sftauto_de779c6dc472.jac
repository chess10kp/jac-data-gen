def calculate_product(numbers: Any) -> object {
    product = 1;
    for num in numbers {
        if (num < 0) {
            continue;
        }
        product *= num;
    }
    return product;
}



with entry {
    print(calculate_product([2, -9]));
    print(calculate_product([34]));
    print(calculate_product([10, 20, 30]));
}
