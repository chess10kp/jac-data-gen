def compute_product(arr: Any) -> object {
    product = 1;
    for num in arr {
        if (((num % 3) == 0) and (num != 4)) {
            product *= num;
        }
    }
    return product;
}



with entry {
    print(compute_product([]));
}
