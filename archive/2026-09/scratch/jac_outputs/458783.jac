"""Calculate the product of all digits in a string."""
def str_product(string: str) -> int {
    product = 1;
    for i in string {
        product *= int(i);
    }
    return product;
}