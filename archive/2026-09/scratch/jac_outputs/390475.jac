"""
    Implements RSA Decryption via the mathematical formula.
    The formula is m=(c**d) % N
    Returns the plain "text" really integer representation of the value.

    :param c: Ciphertext integer.
    :param d: the private key exponent.
    :param n: the modulus.
    :return: the plaintext integer M.
    """
def rsa_decrypt(c: int, d: int, n: int) -> int {
    pow(c, d, n)
}