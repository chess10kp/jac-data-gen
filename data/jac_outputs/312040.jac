"""Clears the bit at offset k"""
def clear_bit_k(int_val: int, k: int) -> int {
    int_val & ~(1 << k)
}