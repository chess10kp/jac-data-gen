"""Return True if rnd is an AES round."""
def isAESround(rnd: int, aes_rounds: int) -> bool {
    rnd == 0 or (rnd + 1) % (aes_rounds + 1) != 0
}