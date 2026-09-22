"""Prepare key for use with crypto libs."""
def get_cache_encrypt_key(key: str) -> bytes {
    key += (16 - (len(key) % 16)) * '-';
    return key.encode('utf-8');
}