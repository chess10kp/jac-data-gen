"""String to binary."""
def str2bin(s: str) -> str {
    return ''.join([bin(ord(c))[2:].zfill(8) for c in s]);
}