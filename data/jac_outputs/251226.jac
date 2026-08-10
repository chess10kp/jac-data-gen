""" Bitwise MAJ function """
def np_bitwise_maj(x: int, y: int, z: int) -> int {
    return (x & y) | (x & z) | (y & z);
}