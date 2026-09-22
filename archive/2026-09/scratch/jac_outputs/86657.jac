"""Returns concatenated product of n with 1-m (until digits > 8)"""
def multiply_by_1_m(n: int) -> int {
    conc_product = "";
    i = 1;
    while len(conc_product) < 9 {
        conc_product += str(n * i);
        i += 1;
    }
    return int(conc_product);
}