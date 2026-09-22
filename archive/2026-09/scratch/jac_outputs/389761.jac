"""Assuming the number is a word in 2s complement, is it negative?"""
def signed_is_negative(num: int, nbits: int = 32) -> int {
    return num & (1 << (nbits - 1));
}