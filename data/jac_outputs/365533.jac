"""Compute arctangent using a series approximation."""
def arctan(talj: int, kvot: int, product: int) -> int {
    summation = 0;
    talj *= product;
    qfactor = 1;
    while talj {
        talj //= kvot;
        summation += talj // qfactor;
        qfactor += 2;
    }
    return summation;
}