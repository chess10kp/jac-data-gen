"""Verify if all the proteins of the bacteriophage are mapped into the contigs."""
def verifyQtyProtContigs(
    qtyProteins: int,
    dictProteins: dict[int, list],
    dictContigs: dict[int, int]
) -> tuple[bool, int] {
    qtyCountProt = 0;
    for (key, _) in dictContigs.items() {
        if key in dictProteins {
            qtyCountProt += len(dictProteins[key]);
        }
    }
    if qtyCountProt == qtyProteins {
        return (True, qtyCountProt);
    }
    return (False, qtyCountProt);
}