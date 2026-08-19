def find_product(nums: Any) -> object {
    product = 1;
    for num in nums {
        product *= num;
    }
    return product;
}



with entry {
    print(find_product([]));
}
