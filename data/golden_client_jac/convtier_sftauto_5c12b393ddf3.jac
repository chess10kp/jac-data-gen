def product_rows(arr: Any) -> object {
    row_product = [];
    for row in arr {
        product = 1;
        for num in row {
            product *= num;
        }
        row_product.append(product);
    }
    row_product = sorted(row_product, reverse=True);
    return row_product;
}



with entry {
    print(product_rows('hello'));
    print(product_rows('Racecar'));
    print(product_rows('abcabc'));
}
