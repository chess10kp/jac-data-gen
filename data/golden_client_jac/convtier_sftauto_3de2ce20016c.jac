def max_pairwise_product(arr: Any) -> object {
    n = len(arr);
    max_product = float('-inf');
    for i in range(n) {
        for j in range((i + 1), n) {
            product = arr[i] * arr[j];
            if (product > max_product) {
                max_product = product;
            }
        }
    }
    return max_product;
}



with entry {
    print(max_pairwise_product([-9]));
    print(max_pairwise_product([10, 20]));
    print(max_pairwise_product([-8, -4, 2, 6]));
}
