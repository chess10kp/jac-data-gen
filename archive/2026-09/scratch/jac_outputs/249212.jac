"""Calculate checksum on value string."""
def checksum(data: str) -> int {
    total = sum([ord(x) for x in data]);
    return total & 255;
}