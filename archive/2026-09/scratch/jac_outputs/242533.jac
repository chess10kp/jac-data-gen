"""Creates a random (hex) string which contains 'size' characters."""
def get_random_string(size: int = 32) -> str {
    return ''.join("{0:02x}".format(b) for b in open('/dev/urandom', 'rb').read(int(size / 2)));
}