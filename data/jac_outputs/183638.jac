"""Figure out allele numbers for a likelihood index (VCF genotype ordering)."""
def genotype_from_likelyhood_index(p: int, n: int, index: int) -> list[str] {
    def recursive_order(_p: int, _n: int, alleles: list[list[str]], suffix: list[str] = []) {
        for a in range(_n) {
            if _p == 1 {
                alleles.append([str(a)] + suffix);
            } elif _p > 1 {
                recursive_order(_p - 1, a + 1, alleles, [str(a)] + suffix);
            }
        }
    }
    alleles_list: list[list[str]] = [];
    recursive_order(p, n, alleles_list);
    return alleles_list[index];
}