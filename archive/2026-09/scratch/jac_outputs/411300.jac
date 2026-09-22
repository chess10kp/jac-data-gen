"""XOR two bytearrays of the same length."""
def xor(bytes_1: bytearray, bytes_2: bytearray) -> bytearray {
    l1 = len(bytes_1);
    assert len(bytes_2) == l1;
    return bytearray(bytes_1[i] ^ bytes_2[i] for i in range(l1));
}