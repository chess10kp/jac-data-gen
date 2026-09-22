"""Product of a list of numbers."""
def _prod(iterable: list[int]) -> int {
    product = 1;
    for x in iterable {
        product *= x;
    }
    return product;
}