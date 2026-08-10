"""Return message RSA-blinded with integer randint for a keypair
   with the provided public exponent and modulus."""
def rsa_blind(message: int, randint: int, exponent: int, modulus: int) -> int {
    return message * pow(randint, exponent, modulus) % modulus;
}