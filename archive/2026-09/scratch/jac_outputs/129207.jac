"""
Divide cipher 16-hex digits into a list of 4 blocks (4 hex digits each),
converted to int.
"""
def get_cipher_block(cipher_text: str) -> list[int] {
    return [int(cipher_text[i:(i + 4)], 16) for i in range(0, len(cipher_text), 4)];
}