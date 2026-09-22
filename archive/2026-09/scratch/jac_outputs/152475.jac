"""Return padded key string used in AES encrypt function."""
def aes_key_pad(key: str) -> str {
    if not key {
        raise ValueError('Key should not be empty!');
    }
    aes_key_length = 32;
    while len(key) < aes_key_length {
        key += key;
    }
    return key[:aes_key_length];
}