"""A helper function for cyclic indexing rotor scans."""
def cyclic_index_i_plus_1(i: int, length: int) -> int {
    return (i + 1) if i + 1 < length else 0;
}